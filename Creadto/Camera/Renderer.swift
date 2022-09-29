//
//  Renderer.swift
//  SceneDepthPointCloud

import Metal
import MetalKit
import ARKit
import CoreImage
import Vision

// MARK: - Core Metal Scan Renderer
final class Renderer {
    var savedCloudURLs = [URL]()
    private var cpuParticlesBuffer = [CPUParticle]()
    var showParticles = false
    var isInViewSceneMode = true
    var isSavingFile = false
    var highConfCount = 0
    var savingError: XError? = nil
    // Maximum number of points we store in the point cloud inital: 15M
    private let maxPoints = 3_000_000
    // Number of sample points on the grid initial: 3M
    var numGridPoints = 700
    // Particle's size in pixels -> 얘 크기를 pixel 크기에 맞춰서 바꾸면 될듯
    private let particleSize: Float = 8
    // We only use portrait orientation in this app
    private let orientation = UIInterfaceOrientation.portrait
    // Camera's threshold values for detecting when the camera moves so that we can accumulate the points
    // set to 0 for continous sampling
    private let cameraRotationThreshold = cos(0 * .degreesToRadian)
    private let cameraTranslationThreshold: Float = pow(0.00, 2)   // (meter-squared)
    // The max number of command buffers in flight
    private let maxInFlightBuffers = 5
    
    private lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)
    private let session: ARSession
    
    // Segmentation에 사용되는 object들
    public var ciContext : CIContext!
    //public var segmentationImage : CIImage?

    // Metal objects and textures
    private let device: MTLDevice
    private let library: MTLLibrary
    private let renderDestination: RenderDestinationProvider
    private let relaxedStencilState: MTLDepthStencilState
    private let depthStencilState: MTLDepthStencilState
    private var commandQueue: MTLCommandQueue
    private lazy var unprojectPipelineState = makeUnprojectionPipelineState()!
    private lazy var rgbPipelineState = makeRGBPipelineState()!
    private lazy var particlePipelineState = makeParticlePipelineState()!
    // texture cache for captured image
    private lazy var textureCache = makeTextureCache()
    private var capturedImageTextureY: CVMetalTexture?
    private var capturedImageTextureCbCr: CVMetalTexture?
    private var depthTexture: CVMetalTexture?
    private var confidenceTexture: CVMetalTexture?
    
    // texture for segmentaion image
    private var segmentationImageTextureY : CVMetalTexture?
    
//    // texture for segmentation & depth image
//    private var segDepthImageTextureY : CVMetalTexture?
//    private var segDepthImageTextureCbCr : CVMetalTexture?
    
    // Multi-buffer rendering pipeline
    private let inFlightSemaphore: DispatchSemaphore
    private var currentBufferIndex = 0
    
    // The current viewport size
    private var viewportSize = CGSize()
    // The grid of sample points
    private lazy var gridPointsBuffer = MetalBuffer<Float2>(device: device,
                                                            array: makeGridPoints(),
                                                            index: kGridPoints.rawValue, options: [])
    
    // RGB buffer
    private lazy var rgbUniforms: RGBUniforms = {
        var uniforms = RGBUniforms()
        uniforms.radius = rgbOn ? 2 : 0
        uniforms.viewToCamera.copy(from: viewToCamera)
        uniforms.viewRatio = Float(viewportSize.width / viewportSize.height)
        return uniforms
    }()
    private var rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()
    // Point Cloud buffer
    private lazy var pointCloudUniforms: PointCloudUniforms = {
        var uniforms = PointCloudUniforms()
        uniforms.maxPoints = Int32(maxPoints)
        uniforms.confidenceThreshold = Int32(confidenceThreshold)
        uniforms.particleSize = particleSize
        uniforms.cameraResolution = cameraResolution
        return uniforms
    }()
    private var pointCloudUniformsBuffers = [MetalBuffer<PointCloudUniforms>]()
    // Particles buffer
    private var particlesBuffer: MetalBuffer<ParticleUniforms>
    private var currentPointIndex = 0
    private var currentPointCount = 0
    
    // Camera data
    private var sampleFrame: ARFrame { session.currentFrame! }
    private lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    private lazy var viewToCamera = sampleFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
    private lazy var lastCameraTransform = sampleFrame.camera.transform
    
    // interfaces
    var confidenceThreshold = 2
    
    var rgbOn: Bool = true {
        didSet {
            // apply the change for the shader
            rgbUniforms.radius = rgbOn ? 2 : 0
        }
    }
    
    init(session: ARSession, metalDevice device: MTLDevice, renderDestination: RenderDestinationProvider) {
        self.session = session
        self.device = device
        self.renderDestination = renderDestination
        library = device.makeDefaultLibrary()!
        ciContext = CIContext(mtlDevice: device)
        
        commandQueue = device.makeCommandQueue()!
        // initialize our buffers
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
            pointCloudUniformsBuffers.append(.init(device: device, count: 1, index: kPointCloudUniforms.rawValue))
        }
        particlesBuffer = .init(device: device, count: maxPoints, index: kParticleUniforms.rawValue)
        // rbg does not need to read/write depth
        let relaxedStateDescriptor = MTLDepthStencilDescriptor()
        relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!
        
        // setup depth test for point cloud
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .lessEqual
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
        
        inFlightSemaphore = DispatchSemaphore(value: maxInFlightBuffers)
        self.loadSavedClouds()
    }
    
    func drawRectResized(size: CGSize) {
        viewportSize = size
    }
   
    private func updateCapturedImageTextures(frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return
        }
        
        capturedImageTextureY = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
        
        segmentationImageTextureY = makeTexture(fromPixelBuffer: frame.segmentationBuffer!, pixelFormat: .r8Unorm, planeIndex: 0)
    }
    
    private func updateDepthTextures(frame: ARFrame) -> Bool {
        guard let depthMap = frame.smoothedSceneDepth?.depthMap,
            let confidenceMap = frame.smoothedSceneDepth?.confidenceMap else {
                return false
        }
        
        /**
                시도 1)
                - CVPixelBuffer(depthMap) -> CIImage -> CGImage -> 1d array
                - CVPixelBuffer(segmentation) -> CIImage -> CGImage -> 1d array
                - 위의 두 array mix -> CGImage -> CVPixelBuffer -> texture
         
         
         let depthMapCIImage = CIImage(cvPixelBuffer: depthMap)
         let depthMapCGImage = ciContext.createCGImage(depthMapCIImage, from: depthMapCIImage.extent)
         let (depth_pixelValues, depth_info) = convertImageToArray(fromCGImage: depthMapCGImage) // width : 256, height : 192 => 256 * 192 = 49152
         
         let segmentationCIImage = CIImage(cvPixelBuffer: frame.segmentationBuffer!)
         let segmentationCGImage = ciContext.createCGImage(segmentationCIImage, from: segmentationCIImage.extent)
         let (seg_pixelValues, seg_info) = convertImageToArray(fromCGImage: segmentationCGImage) // width : 256, height : 192 => 256 * 192 = 49152
         let seg_scale_pixelValues = seg_pixelValues!.map { $0 / UInt8(255) }
         
         // Matrix product(element product)
         let productValues = zip(depth_pixelValues!, seg_scale_pixelValues).map{ $0 * $1 }    // 1차원 배열 곱
         
         // 2차원 배열 생성 후 iterator를 이용하여 값 대입하기 => O(n^2)
         //var product_Matrix = [[UInt8]](repeating: Array(repeating: 0, count : Int(segmentationCIImage.extent.width)), count: Int(segmentationCIImage.extent.height))
         //var product_iter = productValues.makeIterator()
         //product_Matrix = product_Matrix.map { $0.compactMap { _ in product_iter.next()}}    // segmentation * depthMap 2차원 배열
         
         let productCGImage = convertArrayToImage(fromPixelValues: productValues, fromImageInfo: seg_info)
         let productCVPixelBuffer = pixelBufferFromCGImage(image: productCGImage!)
         
         depthTexture = makeTexture(fromPixelBuffer: productCVPixelBuffer, pixelFormat: .r32Float, planeIndex: 0)
         */
        
        /**
                시도 2)
                - CVPixelBuffer(depthMap) --> 1d array
                - depth 1d array * segmentation 1d array
                - 위에서 나온 1d array -> CGImage -> CVPixelBuffer -> texture
         
         let width = CVPixelBufferGetWidth(depthMap)
         let height = CVPixelBufferGetHeight(depthMap)
         CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
         let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)
         var depthMap1DArray : Array<Float32> = []
         let bufferPointer = UnsafeBufferPointer(start: floatBuffer, count: width * height)
         for (index, value) in bufferPointer.enumerated() {
             depthMap1DArray.append(value)
         }
         CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
         
         let segmentationCIImage = CIImage(cvPixelBuffer: frame.segmentationBuffer!)
         let segmentationCGImage = ciContext.createCGImage(segmentationCIImage, from: segmentationCIImage.extent)
         let (seg_pixelValues, seg_info) = convertImageToArray(fromCGImage: segmentationCGImage) // width : 256, height : 192 => 256 * 192 = 49152
         let seg_scale_pixelValues = seg_pixelValues!.map { $0 / UInt8(255) }
         
         let productValues = zip(depthMap1DArray, seg_scale_pixelValues).map{ $0 * Float32($1) }
         
         let productCGImage = convertArrayToImage(fromPixelValues: productValues, fromImageInfo: seg_info)
         let productCVPixelBuffer = pixelBufferFromCGImage(image: productCGImage!)
         
         depthTexture = makeTexture(fromPixelBuffer: productCVPixelBuffer, pixelFormat: .r32Float, planeIndex: 0)
         */
        
        /**
                시도 3)
                - CVPixelBuffer(depthMap) --> 1d array
                - depth 1d array * segmentation 1d array
                - 위에서 나온 1d array -> CVPixelBuffer
                - 위의 CVPixelBuffer -> CIImage 로 변환했으나 렌더링 x
         
         let width = CVPixelBufferGetWidth(depthMap)
         let height = CVPixelBufferGetHeight(depthMap)
         CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
         let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)
         var depthMap1DArray : Array<Float32> = []
         let bufferPointer = UnsafeBufferPointer(start: floatBuffer, count: width * height)
         for (index, value) in bufferPointer.enumerated() {
             depthMap1DArray.append(value)
         }
         CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
         
         let segmentationCIImage = CIImage(cvPixelBuffer: frame.segmentationBuffer!)
         let segmentationCGImage = ciContext.createCGImage(segmentationCIImage, from: segmentationCIImage.extent)
         let (seg_pixelValues, seg_info) = convertImageToArray(fromCGImage: segmentationCGImage) // width : 256, height : 192 => 256 * 192 = 49152
         let seg_scale_pixelValues = seg_pixelValues!.map { $0 / UInt8(255) }
         
         let productValues = zip(depthMap1DArray, seg_scale_pixelValues).map{ $0 * Float32($1) }
         let options: NSDictionary = [:]
         var productCVPixelBuffer : CVPixelBuffer? = nil
         CVPixelBufferCreate(
             kCFAllocatorDefault,
             width,
             height,
             kCVPixelFormatType_DepthFloat32,
             options,
             &productCVPixelBuffer)
         
         depthTexture = makeTexture(fromPixelBuffer: productCVPixelBuffer!, pixelFormat: .r32Float, planeIndex: 0)
         
         */
        
        
        depthTexture = makeTexture(fromPixelBuffer: depthMap, pixelFormat: .r32Float, planeIndex: 0)
        //depthTexture = makeTexture(fromPixelBuffer: productCVPixelBuffer!, pixelFormat: .r32Float, planeIndex: 0)
        confidenceTexture = makeTexture(fromPixelBuffer: confidenceMap, pixelFormat: .r8Uint, planeIndex: 0)
        return true
    }
    
    private func update(frame: ARFrame) {
        // frame dependent info
        let camera = frame.camera
        let cameraIntrinsicsInversed = camera.intrinsics.inverse
        let viewMatrix = camera.viewMatrix(for: orientation)
        let viewMatrixInversed = viewMatrix.inverse
        let projectionMatrix = camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.001, zFar: 0)
        pointCloudUniforms.viewProjectionMatrix = projectionMatrix * viewMatrix
        pointCloudUniforms.localToWorld = viewMatrixInversed * rotateToARCamera
        pointCloudUniforms.cameraIntrinsicsInversed = cameraIntrinsicsInversed
    }
    
    func draw(in view: MTKView) {
        guard let currentFrame = session.currentFrame,
            let renderDescriptor = renderDestination.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor),
            let segmentationBuffer = currentFrame.segmentationBuffer
            else {
                return
        }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        commandBuffer.addCompletedHandler { [weak self] commandBuffer in
            if let self = self {
                self.inFlightSemaphore.signal()
            }
        }
        
        // update frame data
        update(frame: currentFrame)
        //segmentation(original: currentFrame.capturedImage, mask: segmentationBuffer)
        updateCapturedImageTextures(frame: currentFrame)
        updateDepthTextures(frame: currentFrame)
        
        // handle buffer rotating
        currentBufferIndex = (currentBufferIndex + 1) % maxInFlightBuffers
        pointCloudUniformsBuffers[currentBufferIndex][0] = pointCloudUniforms
        
        if shouldAccumulate(frame: currentFrame) {
            accumulatePoints(frame: currentFrame, commandBuffer: commandBuffer, renderEncoder: renderEncoder)
        }
        
        // check and render rgb camera image
        if rgbUniforms.radius > 0 {
            var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr]
            commandBuffer.addCompletedHandler { buffer in
                retainingTextures.removeAll()
            }
            rgbUniformsBuffers[currentBufferIndex][0] = rgbUniforms
            renderEncoder.setDepthStencilState(relaxedStencilState)
            renderEncoder.setRenderPipelineState(rgbPipelineState)
            renderEncoder.setVertexBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureY!), index: Int(kTextureY.rawValue))
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!), index: Int(kTextureCbCr.rawValue))
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        if self.showParticles, depthTexture != nil {
            // filter turn on/off
            var retainingTextures = [depthTexture]
            commandBuffer.addCompletedHandler{ buffer in
                retainingTextures.removeAll()
            }
            
            rgbUniformsBuffers[currentBufferIndex][0] = rgbUniforms
            renderEncoder.setDepthStencilState(depthStencilState)
            renderEncoder.setRenderPipelineState(particlePipelineState)
            renderEncoder.setVertexBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setVertexTexture(CVMetalTextureGetTexture(depthTexture!), index: Int(kTextureDepth.rawValue))
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(particlePipelineState)
        renderEncoder.setVertexBuffer(pointCloudUniformsBuffers[currentBufferIndex])
        renderEncoder.setVertexBuffer(particlesBuffer)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: currentPointCount)
        
        renderEncoder.endEncoding()
        commandBuffer.present(renderDestination.currentDrawable!)
        commandBuffer.commit()
    }
    
/**
 *  Description : Segmentation 결과를 보여주기 위해, 원본 이미지 + 마스크 이미지 + 배경 이미지를 합친 Filter를 blend 하여 하나의 CIImage를 생성
 *
 *
    private func segmentation(original framePixelBuffer : CVPixelBuffer,
                       mask maskPixelBuffer : CVPixelBuffer) {
        // Create CIImage objects for the video frame and the segmentation mask.
        let originalImage = CIImage(cvPixelBuffer: framePixelBuffer).oriented(.right)
        var maskImage = CIImage(cvPixelBuffer: maskPixelBuffer).oriented(.right)
        // Scale the mask image to fit the bounds of the video frame.
        let scaleX = originalImage.extent.width / maskImage.extent.width
        let scaleY = originalImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        
        // Define RGB vectors for CIColorMatrix filter.
        let vectors = [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ]
        
        // Create a colored background image.
        let backgroundImage = maskImage.applyingFilter("CIColorMatrix",
                                                       parameters: vectors)
        
        // Blend the original, background, and mask images.
        let blendFilter = CIFilter.blendWithRedMask()
        blendFilter.inputImage = originalImage
        blendFilter.backgroundImage = backgroundImage
        blendFilter.maskImage = maskImage
        
        // Set the new, blended image as current.
        segmentationImage = blendFilter.outputImage?.oriented(.right)
    }
 */
    
    private func shouldAccumulate(frame: ARFrame) -> Bool {
        if self.isInViewSceneMode {
            
            return false
        }
        let cameraTransform = frame.camera.transform
        return currentPointCount == 0
            || dot(cameraTransform.columns.2, lastCameraTransform.columns.2) <= cameraRotationThreshold
            || distance_squared(cameraTransform.columns.3, lastCameraTransform.columns.3) >= cameraTranslationThreshold
    }
    
    private func accumulatePoints(frame: ARFrame, commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder) {
        pointCloudUniforms.pointCloudCurrentIndex = Int32(currentPointIndex)
        
        var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr, depthTexture, confidenceTexture]
        //var retainingTextures = [depthTexture]
        
        // 밑에 있는 코드(renderEncoder 작업) command를 모두 수행한 뒤에 호출됨
        commandBuffer.addCompletedHandler { buffer in
            retainingTextures.removeAll()
            // copy gpu point buffer to cpu
            var i = self.cpuParticlesBuffer.count
            while (i < self.maxPoints && self.particlesBuffer[i].position != simd_float3(0.0,0.0,0.0)) {
                //print("particlesBuffer[\(i)] = \(self.particlesBuffer[i].position)")    // Rendering 좌표
                let position = self.particlesBuffer[i].position
                let color = self.particlesBuffer[i].color
                let confidence = self.particlesBuffer[i].confidence
                if confidence == 2 { self.highConfCount += 1 }
                self.cpuParticlesBuffer.append(
                    CPUParticle(position: position,
                                color: color,
                                confidence: confidence))
                i += 1
            }
        }
        
        renderEncoder.setDepthStencilState(relaxedStencilState)
        renderEncoder.setRenderPipelineState(unprojectPipelineState)
        renderEncoder.setVertexBuffer(pointCloudUniformsBuffers[currentBufferIndex])
        renderEncoder.setVertexBuffer(particlesBuffer)
        renderEncoder.setVertexBuffer(gridPointsBuffer)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureY!), index: Int(kTextureY.rawValue))
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!), index: Int(kTextureCbCr.rawValue))
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(depthTexture!), index: Int(kTextureDepth.rawValue))
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(confidenceTexture!), index: Int(kTextureConfidence.rawValue))
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: gridPointsBuffer.count)
        
        currentPointIndex = (currentPointIndex + gridPointsBuffer.count) % maxPoints
        currentPointCount = min(currentPointCount + gridPointsBuffer.count, maxPoints)
        lastCameraTransform = frame.camera.transform
    }
}

// MARK:  - Added Renderer functionality
extension Renderer {
    func toggleParticles() {
        self.showParticles = !self.showParticles
    }
    func toggleSceneMode() {
        self.isInViewSceneMode = !self.isInViewSceneMode
    }
    func getCpuParticles() -> Array<CPUParticle> {
        return self.cpuParticlesBuffer
    }
    
    func saveAsPlyFile(fileName: String,
                       beforeGlobalThread: [() -> Void],
                       afterGlobalThread: [() -> Void],
                       errorCallback: (XError) -> Void,
                       format: String) {
        
        guard !isSavingFile else {
            return errorCallback(XError.alreadySavingFile)
        }
        guard !cpuParticlesBuffer.isEmpty else {
            return errorCallback(XError.noScanDone)
        }
        
        DispatchQueue.global().async {
            self.isSavingFile = true
            DispatchQueue.main.async {
                for task in beforeGlobalThread { task() }
            }

//            do { self.savedCloudURLs.append(try PLYFile.write(
//                    fileName: fileName,
//                    cpuParticlesBuffer: &self.cpuParticlesBuffer,
//                    highConfCount: self.highConfCount,
//                    format: format)) } catch {
//                self.savingError = XError.savingFailed
//            }
    
            DispatchQueue.main.async {
                for task in afterGlobalThread { task() }
            }
            self.isSavingFile = false
        }
    }
    
    func clearParticles() {
        highConfCount = 0
        currentPointIndex = 0
        currentPointCount = 0
        cpuParticlesBuffer = [CPUParticle]()
        rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()
        pointCloudUniformsBuffers = [MetalBuffer<PointCloudUniforms>]()
        
        commandQueue = device.makeCommandQueue()!
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
            pointCloudUniformsBuffers.append(.init(device: device, count: 1, index: kPointCloudUniforms.rawValue))
        }
        particlesBuffer = .init(device: device, count: maxPoints, index: kParticleUniforms.rawValue)
    }
    
    func loadSavedClouds() {
        let docs = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        savedCloudURLs = try! FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }
}

// MARK: - Metal Renderer Helpers
private extension Renderer {
    func makeUnprojectionPipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "unprojectVertex") else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        // false -> no fragments are processed and vertex shader function must return void
        descriptor.isRasterizationEnabled = false
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func makeRGBPipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "rgbVertex"),
            let fragmentFunction = library.makeFunction(name: "rgbFragment") else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func makeParticlePipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "particleVertex"),
            let fragmentFunction = library.makeFunction(name: "particleFragment") else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    /// Makes sample points on camera image, also precompute the anchor point for animation
    func makeGridPoints() -> [Float2] {
        // cameraResolution = 1920 * 1440
        let gridArea = cameraResolution.x * cameraResolution.y
        let spacing = sqrt(gridArea / Float(numGridPoints))
        let deltaX = Int(round(cameraResolution.x / spacing))
        let deltaY = Int(round(cameraResolution.y / spacing))
        
        var points = [Float2]()
        for gridY in 0 ..< deltaY {
            let alternatingOffsetX = Float(gridY % 2) * spacing / 2
            for gridX in 0 ..< deltaX {
                let cameraPoint = Float2(alternatingOffsetX + (Float(gridX) + 0.5) * spacing, (Float(gridY) + 0.5) * spacing)
                
                points.append(cameraPoint)
            }
        }
        
        return points
    }
    
    func makeTextureCache() -> CVMetalTextureCache {
        // Create captured image texture cache
        var cache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        
        return cache
    }
    
    func makeTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)

        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)

        if status != kCVReturnSuccess {
            texture = nil
        }

        return texture
    }
    
    static func cameraToDisplayRotation(orientation: UIInterfaceOrientation) -> Int {
        switch orientation {
        case .landscapeLeft:
            return 180
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return -90
        default:
            return 0
        }
    }
    
    static func makeRotateToARCameraMatrix(orientation: UIInterfaceOrientation) -> matrix_float4x4 {
        // flip to ARKit Camera's coordinate
        let flipYZ = matrix_float4x4(
            [1, 0, 0, 0],
            [0, -1, 0, 0],
            [0, 0, -1, 0],
            [0, 0, 0, 1] )

        let rotationAngle = Float(cameraToDisplayRotation(orientation: orientation)) * .degreesToRadian
        return flipYZ * matrix_float4x4(simd_quaternion(rotationAngle, Float3(0, 0, 1)))
    }
    
    func convertImageToArray(fromCGImage imageRef: CGImage?) -> (pixelValues: [UInt8]?, imageInfo : [String : Any])
    {
        var imageInfo : [String : Any] = [:]
        
        var pixelValues: [UInt8]?
        if let imageRef = imageRef {
            let width = imageRef.width
            imageInfo["width"] = width
            
            let height = imageRef.height
            imageInfo["height"] = height
            
            let bitsPerComponent = imageRef.bitsPerComponent
            imageInfo["bitsPerComponent"] = bitsPerComponent
            
            let bytesPerRow = imageRef.bytesPerRow / 4
            imageInfo["bytesPerRow"] = bytesPerRow
            
            let totalBytes = height * bytesPerRow
            imageInfo["totalBytes"] = totalBytes

            let colorSpace = CGColorSpaceCreateDeviceGray()
            var intensities = [UInt8](repeating: 0, count: totalBytes)
            let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 0)
            contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))

            pixelValues = intensities
        }
        
        return (pixelValues, imageInfo)
    }

    
    func convertArrayToImage(fromPixelValues pixelValues: [UInt8]?, fromImageInfo imageInfo : [String : Any]) -> CGImage?
    {
        var imageRef: CGImage?
        if var pixelValues = pixelValues {
            imageRef = withUnsafePointer(to: &pixelValues, {
                ptr -> CGImage? in
                var imageRef: CGImage?
                let colorSpaceRef = CGColorSpaceCreateDeviceGray()
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).union(CGBitmapInfo())
                let data = UnsafeRawPointer(ptr.pointee).assumingMemoryBound(to: UInt8.self)
                let releaseData: CGDataProviderReleaseDataCallback = {
                    (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
                }
                
                if let providerRef = CGDataProvider(dataInfo: nil, data: data, size: imageInfo["totalBytes"] as! Int, releaseData: releaseData) {
                    imageRef = CGImage(width: imageInfo["width"] as! Int,
                                       height: imageInfo["height"] as! Int,
                                       bitsPerComponent: imageInfo["bitsPerComponent"] as! Int,
                                       bitsPerPixel: imageInfo["bitsPerComponent"] as! Int,
                                       bytesPerRow: imageInfo["bytesPerRow"] as! Int,
                                       space: colorSpaceRef,
                                       bitmapInfo: bitmapInfo,
                                       provider: providerRef,
                                       decode: nil,
                                       shouldInterpolate: false,
                                       intent: CGColorRenderingIntent.defaultIntent)
                }
                return imageRef
            })
        }

        return imageRef
    }
    
    func convertArrayToImage(fromPixelValues pixelValues: [Float32]?, fromImageInfo imageInfo : [String : Any]) -> CGImage?
    {
        var imageRef: CGImage?
        if var pixelValues = pixelValues {
            imageRef = withUnsafePointer(to: &pixelValues, {
                ptr -> CGImage? in
                var imageRef: CGImage?
                let colorSpaceRef = CGColorSpaceCreateDeviceGray()
                let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue).union(CGBitmapInfo())
                let data = UnsafeRawPointer(ptr.pointee).assumingMemoryBound(to: UInt8.self)
                let releaseData: CGDataProviderReleaseDataCallback = {
                    (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
                }
                
                if let providerRef = CGDataProvider(dataInfo: nil, data: data, size: imageInfo["totalBytes"] as! Int, releaseData: releaseData) {
                    imageRef = CGImage(width: imageInfo["width"] as! Int,
                                       height: imageInfo["height"] as! Int,
                                       bitsPerComponent: imageInfo["bitsPerComponent"] as! Int,
                                       bitsPerPixel: imageInfo["bitsPerComponent"] as! Int,
                                       bytesPerRow: imageInfo["bytesPerRow"] as! Int,
                                       space: colorSpaceRef,
                                       bitmapInfo: bitmapInfo,
                                       provider: providerRef,
                                       decode: nil,
                                       shouldInterpolate: false,
                                       intent: CGColorRenderingIntent.defaultIntent)
                }
                return imageRef
            })
        }

        return imageRef
    }
    
    func pixelBufferFromCGImage(image: CGImage) -> CVPixelBuffer {
        var pxbuffer: CVPixelBuffer? = nil
        let options: NSDictionary = [:]

        let width =  image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow

        let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, image.dataProvider!.data)
        let x = CFDataGetMutableBytePtr(dataFromImageDataProvider)
        
        CVPixelBufferCreateWithBytes(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_DepthFloat32,
            x!,
            bytesPerRow,
            nil,
            nil,
            options,
            &pxbuffer
        )
        return pxbuffer!;
    }
    
    
//    func resizeCIImage(_ inputImage : CIImage, _ size : CGSize) -> CIImage {
//        let resizeFilter = CIFilter(name: "CILanczosScaleTransform")!
//        let scale = size.width / (inputImage.extent.height)
//        let aspectRatio = size.height / ((inputImage.extent.width) * scale)
//
//        resizeFilter.setValue(inputImage, forKey: kCIInputImageKey)
//        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
//        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
//
//        let outputImage = resizeFilter.outputImage!
//        return outputImage
//    }
}

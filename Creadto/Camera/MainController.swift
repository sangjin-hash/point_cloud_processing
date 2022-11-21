import UIKit
import Metal
import MetalKit
import ARKit

final class MainController: UIViewController, ARSessionDelegate {
    private let isUIEnabled = true
    private var clearButton = UIButton(type: .system)
    private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private var rgbButton = UIButton(type: .system)
    private var showSceneButton = UIButton(type: .system)
    private var saveButton = UIButton(type: .system)
    private var flipButton = UIButton(type: .system)
    private let session = ARSession()
    var renderer: Renderer!
    
    private var plyCounter = 0
    private let selectedFormat: String = "Ascii"
    private let fileNameList = ["Front_", "Left_", "Back_", "Right_"]

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        session.delegate = self
        // Set the view to use the default device
        if let view = view as? MTKView {
            view.device = device
            view.backgroundColor = UIColor.clear
            // we need this to enable depth test
            view.depthStencilPixelFormat = .depth32Float
            view.contentScaleFactor = 1
            view.delegate = self
            // Configure the renderer to draw to the view
            renderer = Renderer(session: session, metalDevice: device, renderDestination: view)
            renderer.drawRectResized(size: view.bounds.size)
        }
        
        clearButton = createButton(mainView: self, iconName: "delete_button.png", hidden: !isUIEnabled)
        view.addSubview(clearButton)
        
        showSceneButton = createButton(mainView: self, iconName: "ShutterButton-Recording.png", hidden: !isUIEnabled)
        view.addSubview(showSceneButton)

        rgbButton = createButton(mainView: self, iconName: "blind_button.png", hidden: !isUIEnabled)
        view.addSubview(rgbButton)
        
        flipButton = createButton(mainView: self, iconName: "flip.png", hidden: !isUIEnabled)
        view.addSubview(flipButton)
        
        NSLayoutConstraint.activate([
            clearButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            clearButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            clearButton.widthAnchor.constraint(equalToConstant: 50),
            clearButton.heightAnchor.constraint(equalToConstant: 50),
            
            showSceneButton.widthAnchor.constraint(equalToConstant: 80),
            showSceneButton.heightAnchor.constraint(equalToConstant: 80),
            showSceneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            showSceneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            rgbButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
            rgbButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120),
            rgbButton.widthAnchor.constraint(equalToConstant: 50),
            rgbButton.heightAnchor.constraint(equalToConstant: 50),
            
            flipButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
            flipButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            flipButton.widthAnchor.constraint(equalToConstant: 50),
            flipButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a world-tracking configuration, and
        // enable the scene depth frame-semantic.
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        // Run the view's session
        session.run(configuration)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @objc
    func viewValueChanged(view: UIView) {
        switch view {
        case confidenceControl:
            renderer.confidenceThreshold = confidenceControl.selectedSegmentIndex
            
        case rgbButton:
            renderer.rgbOn = !renderer.rgbOn
            let iconName = renderer.rgbOn ? "blind_button.png": "eye_button.png"
            rgbButton.setBackgroundImage(UIImage(named:iconName), for: .normal)
            
        case clearButton:
            renderer.isInViewSceneMode = true
            renderer.clearParticles()
            if(plyCounter > 0){
                // remove scn file
                try? FileManager.default.removeItem(at: renderer.savedCloudURLs.last!)
                renderer.savedCloudURLs.removeLast()
                
                // remove ply file
                try? FileManager.default.removeItem(at: renderer.savedCloudURLs.last!)
                renderer.savedCloudURLs.removeLast()
                plyCounter -= 1
            }
        
        case showSceneButton:
            renderer.isInViewSceneMode = !renderer.isInViewSceneMode
            if !renderer.isInViewSceneMode {
                if plyCounter % 4 == 0 {
                    renderer.createDirectory()
                }
                renderer.clearParticles()
                self.setShowSceneButtonStyle(isScanning: true)
            } else {
                self.setShowSceneButtonStyle(isScanning: false)
                let format = selectedFormat
                    .lowercased(with: .none)
                    .split(separator: " ")
                    .joined(separator: "_")
                let fileName = fileNameList[plyCounter-1] + renderer.getDate()
                self.renderer.saveAsPlyFile(
                    fileName: fileName,
                    lastCameraTransform: renderer.lastCameraTransform,
                    plyCounter: plyCounter,
                    afterGlobalThread: [afterSave],
                    errorCallback: onSaveError,
                    format: format)
            }
            
        case flipButton:
            goToFrontTrueDepthCameraView()
            
        default:
            break
        }
    }
    
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                if let configuration = self.session.configuration {
                    self.session.run(configuration, options: .resetSceneReconstruction)
                }
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


// MARK: - MTKViewDelegate
extension MainController: MTKViewDelegate {
    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.drawRectResized(size: size)
    }
    
    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        renderer.draw(in : view)
    }
}

// MARK: - Added controller functionality
extension MainController {
    private func setShowSceneButtonStyle(isScanning: Bool) -> Void {
        if isScanning {
            plyCounter += 1
            self.showSceneButton.setBackgroundImage(
                UIImage(named: "ShutterButton-Selected"), for: .normal)
        } else {
            self.showSceneButton.setBackgroundImage(
                UIImage(named: "ShutterButton-Recording"), for: .normal)
        }
    }
    
    func onSaveError(error: XError) {
        displayErrorMessage(error: error)
        renderer.savingError = nil
    }
    
    func afterSave() -> Void {
        let err = renderer.savingError
        if err == nil {
            return
        }
        try? FileManager.default.removeItem(at: renderer.savedCloudURLs.last!)
        renderer.savedCloudURLs.removeLast()
        onSaveError(error: err!)
    }
    
    func displayErrorMessage(error: XError) -> Void {
        var title: String
        switch error {
            case .alreadySavingFile: title = "Save in Progress Please Wait."
            case .noScanDone: title = "No scan to Save."
            case.savingFailed: title = "Failed To Write File."
        }
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 1.75
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func goToFrontTrueDepthCameraView() {
        let trueDepthCameraController = TrueDepthCameraController()
        present(trueDepthCameraController, animated: true, completion: nil)
        dismiss(animated: true)
    }
}

// MARK: - RenderDestinationProvider
protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}

extension SCNNode {
    func cleanup() {
        for child in childNodes {
            child.cleanup()
        }
        self.geometry = nil
    }
}

func createButton(mainView: MainController, iconName: String, hidden: Bool) -> UIButton {
    let button = UIButton(type: .system)
    button.isHidden = hidden
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setBackgroundImage(UIImage(named: iconName), for: .normal)
    button.addTarget(mainView, action: #selector(mainView.viewValueChanged), for: .touchDown)
    return button
}

extension MTKView: RenderDestinationProvider {
    
}

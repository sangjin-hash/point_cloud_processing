import UIKit
import Metal
import MetalKit
import ARKit

final class MainController: UIViewController, ARSessionDelegate {
    private let isUIEnabled = true
    private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private var rgbButton = UIButton(type: .system)
    private var showSceneButton = UIButton(type: .system)
    private var saveButton = UIButton(type: .system)
    private var flipButton = UIButton(type: .system)
    private var segmentationToggle = UISwitch()
    private let session = ARSession()
    var renderer: Renderer!
    
    var plyCounter: Int = 0
//    private var directoryURL: URL? = nil
    
    private let selectedFormat: String = "Ascii"
    //private let selectedFormat: String = "Binary Little Endian"
    let fileNameList = ["Front_", "Left_", "Back_", "Right_"]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(dataReceived(_:)), name: .sendDirectoryData, object: nil)
        
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
        
        showSceneButton = createButton(mainView: self, iconName: "ShutterButton-Recording.png", hidden: !isUIEnabled)
        view.addSubview(showSceneButton)

        rgbButton = createButton(mainView: self, iconName: "blind_button.png", hidden: !isUIEnabled)
        rgbButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        rgbButton.layer.cornerRadius = 25
        rgbButton.layer.masksToBounds = true
        view.addSubview(rgbButton)
        
        flipButton = createButton(mainView: self, iconName: "refresh.png", hidden: !isUIEnabled)
        flipButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        flipButton.layer.cornerRadius = 25
        flipButton.layer.masksToBounds = true
        view.addSubview(flipButton)
        
        segmentationToggle.addTarget(self, action: #selector(self.switchStateDidChange(_:)), for: .valueChanged)
        segmentationToggle.setOn(true, animated: false)
        segmentationToggle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentationToggle)
        
        NSLayoutConstraint.activate([
            rgbButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30),
            rgbButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            rgbButton.widthAnchor.constraint(equalToConstant: 50),
            rgbButton.heightAnchor.constraint(equalToConstant: 50),
            
            showSceneButton.widthAnchor.constraint(equalToConstant: 80),
            showSceneButton.heightAnchor.constraint(equalToConstant: 80),
            showSceneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            showSceneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            flipButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
            flipButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            flipButton.widthAnchor.constraint(equalToConstant: 50),
            flipButton.heightAnchor.constraint(equalToConstant: 50),
            
            segmentationToggle.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            segmentationToggle.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 50),
            segmentationToggle.widthAnchor.constraint(equalToConstant: 120),
            segmentationToggle.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func switchStateDidChange(_ sender: UISwitch!){
        if (sender.isOn == true){
            print("true")
            renderer.isSegmentationWork = true
        }
        else{
            print("false")
            renderer.isSegmentationWork = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a world-tracking configuration, and
        // enable the scene depth frame-semantic.
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        configuration.worldAlignment = .camera
//        // When auto focus is on, the deviation of the calibration is larger than when it is off.
//        configuration.isAutoFocusEnabled = true
        
        // A Boolean value specifying whether ARKit analyzes scene lighting in captured camera images
        //configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        session.run(configuration)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @objc private func dataReceived(_ notification : Notification){
        self.plyCounter = notification.userInfo?[NotificationKey.plyCounter] as! Int
        renderer.directoryURL = notification.userInfo?[NotificationKey.directoryURL] as? URL
        print("[MainController] dataReceived")
        print("plyCounter = \(self.plyCounter) url = \(renderer.directoryURL)")
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
                self.renderer.captureFrame(plyCounter: plyCounter)
                let format = selectedFormat
                    .lowercased(with: .none)
                    .split(separator: " ")
                    .joined(separator: "_")
                let fileName = fileNameList[plyCounter % 4] + renderer.getDate()
                self.renderer.saveAsPlyFile(
                    fileName: fileName,
                    plyCounter: plyCounter,
                    afterGlobalThread: [afterSave, renderer.clearParticles],
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
            segmentationToggle.isEnabled = false
            self.showSceneButton.setBackgroundImage(
                UIImage(named: "ShutterButton-Selected"), for: .normal)
        } else {
            segmentationToggle.isEnabled = true
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
            let previewVC = PreviewController(scnURL: renderer.savedCloudURLs.last!)
            previewVC.mainController = self
            previewVC.modalPresentationStyle = .overFullScreen
            present(previewVC, animated:true, completion: nil)
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
    
    private func goToFrontTrueDepthCameraView() {
        let trueDepthCameraController = TrueDepthCameraController()
        present(trueDepthCameraController, animated: true, completion: nil)
        NotificationCenter.default.post(name: .sendDirectoryData,
                                        object: nil,
                                        userInfo: [NotificationKey.plyCounter : plyCounter, NotificationKey.directoryURL : renderer.directoryURL])
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

extension Notification.Name {
    static let sendDirectoryData = Notification.Name("sendDirectoryData")
}

enum NotificationKey {
    case plyCounter
    case directoryURL
}

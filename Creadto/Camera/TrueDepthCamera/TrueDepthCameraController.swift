//
//  TrueDepthCameraController.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/16.
//

import UIKit
import StandardCyborgUI
import StandardCyborgFusion

class TrueDepthCameraController : UIViewController {
    private var lastScene: SCScene?
    private var lastSceneDate: Date?
    private var lastSceneThumbnail: UIImage?
    private var scenePreviewVC: ScenePreviewViewController?
    
    private lazy var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private lazy var sceneGltfURL = documentsURL.appendingPathComponent("scene.gltf")
    private lazy var sceneThumbnailURL = documentsURL.appendingPathComponent("scene.png")

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadScene()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        startScanning()
    }
    
    private func startScanning() {
        #if targetEnvironment(simulator)
        let alert = UIAlertController(title: "Simulator Unsupported", message: "There is no depth camera available on the iOS Simulator. Please build and run on an iOS device with TrueDepth", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
        #else
        let scanningVC = ScanningViewController()
        scanningVC.delegate = self
        scanningVC.generatesTexturedMeshes = true
        scanningVC.modalPresentationStyle = .automatic
        present(scanningVC, animated: true)
        #endif
    }
        
    @objc private func deletePreviewedSceneTapped() {
        deleteScene()
        dismiss(animated: true)
    }
    
    @objc private func dismissPreviewedScanTapped() {
        dismiss(animated: false)
    }
    
    @objc private func savePreviewedSceneTapped() {
        saveScene(scene: scenePreviewVC!.scScene, thumbnail: scenePreviewVC?.renderedSceneImage)
        dismiss(animated: true)
    }
    
    // MARK: - Scene I/O
    
    private func loadScene() {
        if
            FileManager.default.fileExists(atPath: sceneGltfURL.path),
            let gltfAttributes = try? FileManager.default.attributesOfItem(atPath: sceneGltfURL.path),
            let dateCreated = gltfAttributes[FileAttributeKey.creationDate] as? Date
        {
            lastScene = SCScene(gltfAtPath: sceneGltfURL.path)
            lastSceneDate = dateCreated
            lastSceneThumbnail = UIImage(contentsOfFile: sceneThumbnailURL.path)
        }
    }
    
    private func saveScene(scene: SCScene, thumbnail: UIImage?) {
        scene.writeToGLTF(atPath: sceneGltfURL.path)
        
        if let thumbnail = thumbnail, let pngData = thumbnail.pngData() {
            try? pngData.write(to: sceneThumbnailURL)
        }
        
        lastScene = scene
        lastSceneThumbnail = thumbnail
        lastSceneDate = Date()
    }
    
    private func deleteScene() {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: sceneGltfURL.path) {
            try? fileManager.removeItem(at: sceneGltfURL)
        }
        
        if fileManager.fileExists(atPath: sceneThumbnailURL.path) {
            try? fileManager.removeItem(at: sceneThumbnailURL)
        }
        
        lastScene = nil
        lastSceneThumbnail = nil
        lastSceneDate = nil
    }
}

extension TrueDepthCameraController: ScanningViewControllerDelegate {
    func scanningViewControllerDidCancel(_ controller: ScanningViewController) {
        dismiss(animated: true)
    }
    
    func scanningViewController(_ controller: ScanningViewController, didScan pointCloud: SCPointCloud) {
        let vc = ScenePreviewViewController(pointCloud: pointCloud, meshTexturing: controller.meshTexturing, landmarks: nil)
        vc.leftButton.addTarget(self, action: #selector(dismissPreviewedScanTapped), for: UIControl.Event.touchUpInside)
        vc.rightButton.addTarget(self, action: #selector(savePreviewedSceneTapped), for: UIControl.Event.touchUpInside)
        vc.leftButton.setTitle("Rescan", for: UIControl.State.normal)
        vc.rightButton.setTitle("Save", for: UIControl.State.normal)
        vc.leftButton.backgroundColor = UIColor(named: "DestructiveAction")
        vc.rightButton.backgroundColor = UIColor(named: "SaveAction")
        scenePreviewVC = vc
        controller.present(vc, animated: false)
    }

}

private extension URL {
    static let documentsURL: URL = {
        guard let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, false).first
            else { fatalError("Failed to find the documents directory") }
        
        // Annoyingly, this gives us the directory path with a ~ in it, so we have to expand it
        let tildeExpandedDocumentsDirectory = (documentsDirectory as NSString).expandingTildeInPath
        
        return URL(fileURLWithPath: tildeExpandedDocumentsDirectory)
    }()
}

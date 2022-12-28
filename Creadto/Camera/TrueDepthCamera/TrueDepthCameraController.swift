//
//  TrueDepthCameraController.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/16.
//

import UIKit
import StandardCyborgUI
import StandardCyborgFusion
import SceneKit

class TrueDepthCameraController : UIViewController {
    private var lastScene: SCScene?
    private var lastSceneDate: Date?
    private var lastSceneThumbnail: UIImage?
    private var scenePreviewVC: ScenePreviewViewController?
    
    private lazy var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var plyCounter: Int = 0
    private var directoryURL: URL? = nil
    
    private var sceneThumbnailURL: URL? = nil
    private var scenePlyURL: URL? = nil
    private var sceneSCNURL: URL? = nil
    
    private var pointCloud : Array<PointCloudVertex> = []
    private var convertedScene = SCNScene()

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
        NotificationCenter.default.addObserver(self, selector: #selector(dataReceived(_:)), name: .sendDirectoryData, object: nil)
        // loadScene()
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
        scanningVC.modalPresentationStyle = .fullScreen
        scanningVC.modalTransitionStyle = .flipHorizontal
        present(scanningVC, animated: true)
        #endif
    }
    
    @objc private func dataReceived(_ notification : Notification){
        self.plyCounter = notification.userInfo?[NotificationKey.plyCounter] as! Int
        self.directoryURL = notification.userInfo?[NotificationKey.directoryURL] as? URL
        print("[TrueDepthCameraController] dataReceived")
        print("plyCounter = \(self.plyCounter) url = \(self.directoryURL)")
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
    
//    private func loadScene() {
//        var isDir:ObjCBool = true
//        if !FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir) {
//            do {
//                try FileManager.default.createDirectory(atPath: directoryURL.path,
//                                                        withIntermediateDirectories: false)
//            } catch let e as NSError {
//                print(e.localizedDescription)
//            }
//        }
//
//        if
//            FileManager.default.fileExists(atPath: sceneGltfURL.path),
//            let gltfAttributes = try? FileManager.default.attributesOfItem(atPath: sceneGltfURL.path),
//            let dateCreated = gltfAttributes[FileAttributeKey.creationDate] as? Date
//        {
//            lastScene = SCScene(gltfAtPath: sceneGltfURL.path)
//            lastSceneDate = dateCreated
//            lastSceneThumbnail = UIImage(contentsOfFile: sceneThumbnailURL.path)
//        }
//    }
    
    private func saveScene(scene: SCScene, thumbnail: UIImage?) {
        if plyCounter == 0 { createDirectory() }
        let fileName = "Face"
        self.scenePlyURL = directoryURL!.appendingPathComponent("\(fileName).ply")
        self.sceneSCNURL = directoryURL!.appendingPathComponent("\(fileName).scn")
        self.sceneThumbnailURL = directoryURL!.appendingPathComponent("\(fileName).png")
        scene.pointCloud!.writeToPLY(atPath: scenePlyURL!.path)
        
        let cloud = self.convertPLYToSCN(file: self.scenePlyURL!)
        cloud.name = "cloud"
        
        self.convertedScene.rootNode.enumerateChildNodes{ (node, stop) in
            node.removeFromParentNode()
        }
        self.convertedScene.rootNode.addChildNode(cloud)
        
        self.saveConvertedScene(path: sceneSCNURL!.path)
        
        if let thumbnail = thumbnail, let pngData = thumbnail.pngData() {
            try? pngData.write(to: sceneThumbnailURL!)
        }
        
        plyCounter += 1
        NotificationCenter.default.post(name: .sendDirectoryData,
                                        object: nil,
                                        userInfo: [NotificationKey.plyCounter : plyCounter, NotificationKey.directoryURL : directoryURL])
        
        print("[TrueDepthCameraController] saveScene")
        print("plyCounter = \(self.plyCounter) url = \(self.directoryURL)")
    }
    
    private func convertPLYToSCN(file : URL) -> SCNNode{
        let data = try! String(contentsOf: file, encoding: .ascii)
        var lines = data.components(separatedBy: "\n")
        
        while !lines.isEmpty {
            let line = lines.removeFirst()
            if line.hasPrefix("end_header") {
                break
            }
        }
        
        self.pointCloud = lines.filter {$0 != ""}
            .map({ (line : String) -> PointCloudVertex in
                let elements = line.components(separatedBy: " ")
                
                return PointCloudVertex(
                    x: Float(elements[0])!,
                    y: Float(elements[1])!,
                    z: Float(elements[2])!,
                    r: Float(elements[6])! / 255.0,
                    g: Float(elements[7])! / 255.0,
                    b: Float(elements[8])! / 255.0)
            })
        
        let node = SCNFile.buildNode(points: self.pointCloud)
        return node
    }
    
    func saveConvertedScene(path: String){
        let success = convertedScene.write(to: URL.init(fileURLWithPath:path), options: nil, delegate: nil) { (totalProgress, error, stop) in
            print("Progress \(totalProgress) Error: \(String(describing: error))")
        }
        print("Success : \(success)")
    }
    
    private func deleteScene() {
//        let fileManager = FileManager.default
//
//        if fileManager.fileExists(atPath: scenePlyURL!.path) {
//            try? fileManager.removeItem(at: scenePlyURL!)
//        }
//
//        if fileManager.fileExists(atPath: sceneThumbnailURL!.path) {
//            try? fileManager.removeItem(at: sceneThumbnailURL!)
//        }
//
//        plyCounter -= 1
//        if plyCounter == 0 {
//            if fileManager.fileExists(atPath: directoryURL!.path) {
//                try? fileManager.removeItem(at: directoryURL!)
//            }
//            directoryURL = nil
//        }
//
//        NotificationCenter.default.post(name: .sendDirectoryData,
//                                        object: nil,
//                                        userInfo: [NotificationKey.plyCounter : plyCounter, NotificationKey.directoryURL : directoryURL])
    }
    
    func getDate() -> String {
        let now = Date()
        let date = DateFormatter()
        date.locale = Locale(identifier: "ko_kr")
        date.timeZone = TimeZone(abbreviation: "KST")
        date.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let directoryName = date.string(from: now)
        return directoryName
    }
    
    func createDirectory() {
        let directoryName = getDate()
        self.directoryURL = documentsURL.appendingPathComponent(directoryName)
        
        do {
            try FileManager.default.createDirectory(atPath: directoryURL!.path,
                                            withIntermediateDirectories: false)
        } catch let e as NSError {
            print(e.localizedDescription)
        }
    }
}

extension TrueDepthCameraController: ScanningViewControllerDelegate {
    func scanningViewControllerDidCancel(_ controller: ScanningViewController) {
        NotificationCenter.default.post(name: .sendDirectoryData,
                                        object: nil,
                                        userInfo: [NotificationKey.plyCounter : plyCounter,
                                                   NotificationKey.directoryURL : directoryURL])
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

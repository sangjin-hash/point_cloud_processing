//
//  ExportViewModel.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/15.
//

import Alamofire
import UniformTypeIdentifiers
import SceneKit


class ConvertViewModel : ObservableObject {
    private let apiURL = URL(string: "http://49.175.197.110:49152")
    @Published var isLock = false
    @Published var progressAmount = 0.0
    @Published var statusIndex = 0
    
    private var plyTotalCounter = 0
    private var plyCounter = 0
    private var totalPointCount = 0
    private var pointArray = [Int]()
    private var client_expectedTime = 0
    private var server_expectedTime = 0
    
    private var uploadProgressOffset = 0.0
    private var processProgressOffset = 0.0
    private let downloadProgressOffset = 0.03
    
    private var server_start = 0
    
    var fileController = FileController()
    var jsonURL : URL?
    
    private func initVariables() {
        self.plyTotalCounter = 0
        self.plyCounter = 0
        self.progressAmount = 0.0
        self.statusIndex = 0
    }
    
    private func checkPLYFile(fileURL : URL) -> Bool {
        if(fileURL.pathExtension != "ply"){
            return false
        } else {
            return true
        }
    }
    
    private func checkVertexCount(plyList : [URL]) {
        plyList.map{ file in
            let ply = try! Data(contentsOf: file)
            guard let plyString = String(data: ply, encoding: .utf8) else {
                print("Error converting data to string")
                return
            }
            
            let lines = plyString.components(separatedBy: ["\n", "\r"])
            var vertexCount: Int
            for line in lines {
                if(line.hasPrefix("element vertex")) {
                    vertexCount = Int(line.components(separatedBy: " ")[2])!
                    print("vertexCount = \(vertexCount)")
                    totalPointCount += vertexCount
                    pointArray.append(vertexCount)
                    break
                }
            }
        }
    }
   
    func sendToServer(url : URL){
        let fileList = fileController.getContentsOfDirectory(url: url)
        var _plyList : [URL] = []
        self.initVariables()
        
        fileList.map{ file in
            if(checkPLYFile(fileURL: file)){
                _plyList.append(file)
                self.plyTotalCounter += 1
            }
        }
        
        let plyList = _plyList
        
        Task {
            do {
                checkVertexCount(plyList: plyList)
                try await sendDataCounter(counter: self.plyTotalCounter)
                for i in 0...self.plyTotalCounter-1 {
                    let filePath = plyList[i]
                    let mimeType = filePath.getMimeType()
                    let fileName = filePath.path.components(separatedBy: "/").last!

                    let fileData = try? Data(contentsOf: filePath)
                    let start = CFAbsoluteTimeGetCurrent()
                    try await fileUpload(fileData: fileData ?? Data(), fileName: fileName, mimeType: mimeType, start : start)
                }

                DispatchQueue.main.async { [weak self] in
                    self?.statusIndex = 2
                }


                print("4. fileUpload 끝 && observeStatus")

                while(true){
                    let res = try await observeStatus(saveURL: url)
                    if(res.Status == "Meshed") {
                        DispatchQueue.main.async { [weak self] in
                            self?.statusIndex = 3
                        }
                        break;
                    } else if(res.Status != "Received") {
                        self.server_start += 1
                        if(server_start < self.server_expectedTime){
                            let time_percent = Double(self.server_start) / Double(self.server_expectedTime) * 100.0
                            let result = Double(time_percent) * processProgressOffset
                            
                            DispatchQueue.main.async { [weak self] in
                                let uploadProgressAmount = self!.uploadProgressOffset * 100.0
                                self?.progressAmount = result + uploadProgressAmount
                            }
                            sleep(1)
                        }else{
                            sleep(5)
                            print("Process time exceed expected time")
                        }
                    }
                    else {
                        sleep(5)
                        print("status = \(res.Status)")
                    }
                }
                print("5. fileDownload 호출")
                try await fileDownload(saveURL: url)
            } catch {
                print("sendDataCounter Error")
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.isLock.toggle()
            }
            
        }
        
    }
    
    private func sendDataCounter(counter: Int) async throws -> UserData {
        print("2. sendDataCounter 호출")
        let counterToString = String(counter)
        
        return try await AF.request(apiURL!,
                                    method: .post,
                                    parameters: ["Counter" : counterToString],
                                    encoding: URLEncoding.default,
                                    headers: ["Content-Type" : "application/octet-stream"])
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            switch response.result {
            case .success(let value) :
                do {
                    print("sendDataCounter response Success")
                } catch {
                    print("sendDataCounter response error")
                }
            case .failure(let error) :
                print(error)
            }
        }
        .serializingDecodable()
        .value
    }
    
    private func observeStatus(saveURL : URL) async throws -> UserData {
        print("observeStatus 호출")
        return try await AF.request(apiURL!,
                   method: .post,
                   parameters: ["Status" : "check"],
                   encoding: URLEncoding.default,
                   headers: ["Content-Type" : "application/octet-stream"])
        .validate(statusCode: 200..<300)
        .responseJSON { response in
            switch response.result {
            case .success(let value) :
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                    let _userData = try JSONDecoder().decode(UserData.self, from: data)
                    print("observeStatus response = \(_userData)")
                    
                    if(_userData.Status == "Measured") {
                        let jsonData = _userData.Data!.data(using: .utf8)!
                        self.jsonURL = saveURL.appendingPathComponent("Measurement.json")
                        try! jsonData.write(to: self.jsonURL!)
                    } else {}
                } catch {
                    print("observeStatus response error")
                }
            case .failure(let error) :
                print(error)
            }
        }
        .serializingDecodable()
        .value
    }
    
    
    private func fileUpload(fileData : Data, fileName: String, mimeType: String, start: CFAbsoluteTime) async throws -> UserData {
        return try await AF.upload(multipartFormData: { multipart in
            multipart.append(fileData,
                             withName: "ply",
                             fileName: fileName,
                             mimeType:  mimeType)
        }, to: apiURL!, method: .post).uploadProgress(closure: {
            progress in
            if(self.plyCounter > 0) {
                let n = progress.fractionCompleted + Double(self.plyCounter - 1)
                let m = Double(self.plyTotalCounter - 1)
                let result = n * self.uploadProgressOffset / m * 100.0
                
                DispatchQueue.main.async { [weak self] in
                    self?.progressAmount = result
                }
            }
        })
        .responseJSON {
            response in
            switch response.result {
            case .success(let value) :
                do{
                    print("fileUpload response = Success")
                    if(self.plyCounter == 0) {
                        let end = (CFAbsoluteTimeGetCurrent() - start)
                        let _end = String(format: "%.2f", end)
                        
                        // pointArray[0] : _end = totalPointCount - pointArray[0] : x
                        self.client_expectedTime = Int(Double(self.totalPointCount - self.pointArray[0]) * Double(_end)! / Double(self.pointArray[0]))
                        print("client_expectedTime = \(self.client_expectedTime)")
                        
                        // [Server] 90909(Number of points) : 1s = totalPointCount : server_expected_time
                        self.server_expectedTime = Int(self.totalPointCount / 90909)
                        print("Server_expectedTime = \(self.server_expectedTime)")
                        let totalTime = self.client_expectedTime + self.server_expectedTime
                        
                        self.uploadProgressOffset = 0.97 * Double(self.client_expectedTime) / Double(totalTime)
                        self.processProgressOffset = 0.97 - self.uploadProgressOffset
                        
                        print("uploadProgressOffset = \(self.uploadProgressOffset)")
                        print("processProgressOffset = \(self.processProgressOffset)")
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.statusIndex = 1
                        }
                    }
                    self.plyCounter += 1
                } catch {
                    print("fileUpload response error")
                }
                
            case .failure(let error) :
                print(error)
            }
        }
        .serializingDecodable()
        .value
    }
    
    private func fileDownload(saveURL : URL){
        AF.request(apiURL!,
                   method: .post,
                   parameters: ["mesh" : "request"],
                   encoding: URLEncoding.default,
                   headers: ["Content-Type" : "application/octet-stream"])
        .downloadProgress{ (progress) in
            let result = progress.fractionCompleted * 100.0 * self.downloadProgressOffset
            DispatchQueue.main.async { [weak self] in
                self?.progressAmount += result
            }
        }
        .validate(statusCode: 200..<300)
        .response{ response in
            switch response.result {
            case .success :
                let path = saveURL.appendingPathComponent("Mesh.ply")
                if let _data = response.data{
                    try! _data.write(to: path)
                    self.convertToPNG(path: path)
                    print("fileDownload Save file 성공")
                }else{
                    print("fileDownload Data is nil")
                }
            case .failure(let error):
                print("Error: ", error)
            }
            
        }
    }
    
    private func convertToPNG(path : URL){
        let scene = try! SCNScene(url: path, options: nil)
        let scnView = SCNView()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0 , y: 5, z:10)
        scene.rootNode.addChildNode(cameraNode)
        
        scnView.scene = scene
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling2X
        scnView.backgroundColor = UIColor.clear
        
        let previewImage = scnView.snapshot()
        let pngData = previewImage.pngData()
        let previewImageURL = path.deletingLastPathComponent().appendingPathComponent("Mesh.png")
        try? pngData!.write(to: previewImageURL)
    }
}

extension URL {
    func getMimeType() -> String {
        let pathExtension = self.pathExtension
        if let type = UTType(filenameExtension: pathExtension) {
            if let mimetype = type.preferredMIMEType {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

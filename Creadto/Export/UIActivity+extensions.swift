//
//  UIActivity+extensions.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/02.
//

import Foundation
import UIKit
import Alamofire
import UniformTypeIdentifiers

final class ExportActivity : UIActivity {
    private let apiURL : String = "http://192.168.219.128:3000"
    var mainController = MainController()
    
    override class var activityCategory: UIActivity.Category { return .share }
    
    override var activityType:  ActivityType? { return .exportToServer }
    override var activityTitle: String? { return "Export" }
    override var activityImage: UIImage? { return UIImage(named: "") }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        let filePath = activityItems.last as? URL
        let mimeType = filePath?.getMimeType()
        let fileName = filePath!.path.components(separatedBy: "/").last!
        
        do{
            let fileData = try? Data(contentsOf: filePath!)
            fileUpload(
                fileData: fileData ?? Data(),
                fileName: fileName,
                mimeType: mimeType ?? "")
        } catch {
            print("Data 생성 오류")
        }
    }
    
    private func fileUpload(fileData : Data, fileName: String, mimeType: String){
        
        guard let url = URL(string: apiURL) else { return }
        
        AF.upload(multipartFormData: { multipart in
            multipart.append(fileData,
                             withName: "ply",
                             fileName: fileName,
                             mimeType:  mimeType)
        }, to: url, method: .post).uploadProgress(closure: {
            progress in
            print(progress.fractionCompleted * 100)
        })
        .responseJSON {
            response in
            switch response.result {
            case .success(let value) :
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                    let userData = try JSONDecoder().decode(userData.self, from: data)
                    print("userData = \(userData)")
                    
                    switch(userData.Status){
                    case "Idle", "Received", "Loaded":
                        sleep(5)
                        self.observeStatus()
                    case "Meshed" :
                        if let _data = userData.Data {
                            let path = FileManager.default.urls(for: .documentDirectory,
                                                                in: .userDomainMask)[0].appendingPathComponent("myFile.ply")
                            try! _data.write(to: path)
                            print("Save the file")
                        } else{
                            print("Not save the file")
                        }
                        
                    default :
                        print("default")
                    }
                    
                } catch {
                    print("response error")
                }
            case .failure(let error) :
                print(error)
            }
        }
    }
    
    private func observeStatus(){
        guard let url = URL(string: apiURL) else { return }
        AF.request(url,
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
                    let userData = try JSONDecoder().decode(userData.self, from: data)
                    print("userData2 = \(userData)")
                    
                    while(true) {
                        if(userData.Status == "Meshed"){
                            self.fileDownload()
                            break
                        }
                        else{
                            sleep(5)
                            self.fileDownload()
                        }
                    }
                } catch {
                    print("response error")
                }
            case .failure(let error) :
                print(error)
            }
        }
    }
    
    private func fileDownload(){
        guard let url = URL(string: apiURL) else { return }
        AF.request(url,
                   method: .post,
                   parameters: nil,
                   encoding: URLEncoding.default,
                   headers: ["Content-Type" : "application/octet-stream"])
        .validate(statusCode: 200..<300)
        .response{ response in
            switch response.result {
            case .success :
                let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("myFile.ply")
                if let _data = response.data{
                    try! _data.write(to: path)
                    print("Save file 성공")
                }else{
                    print("Data is nil")
                }
            case .failure(let error):
                print("Error: ", error)
            }
            
        }
    }
}

extension UIActivity.ActivityType {
    public static let exportToServer = UIActivity.ActivityType(rawValue: "Export")
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

struct userData : Codable {
    let Status : String
    let Data : Data?
}

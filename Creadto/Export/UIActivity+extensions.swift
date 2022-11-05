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
    private let apiURL : String = "http://192.168.219.102:3000"
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
        
        do {
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
        .response{
            response in
            if let data = response.data{
                let path = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask)[0].appendingPathComponent("myFile.ply")
                try! data.write(to: path)
                print("저장 성공")
                
            } else{
                print("Network Something went wrong")
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

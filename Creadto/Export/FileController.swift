//
//  FileController.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/11.
//

import Foundation

class FileController : ObservableObject {
    func getContentsOfDirectory(url: URL) -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        } catch {
            print(error)
            return []
        }
    }
}

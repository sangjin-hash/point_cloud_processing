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
            var list = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            list.sort {
                ($0.lastPathComponent) < ($1.lastPathComponent)
            }
            return list
        } catch {
            print(error)
            return []
        }
    }
}

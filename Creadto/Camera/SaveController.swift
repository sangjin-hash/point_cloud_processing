//
//  SaveController.swift
//  SceneDepthPointCloud

import SwiftUI
import Foundation

class SaveController : UIViewController, UITextFieldDelegate {
    private var exportData = [URL]()
    private let selectedFormat: String = "Ascii"
    
    private let mainImage = UIImageView(image: .init(named: "save"))
    private let saveCurrentButton = UIButton(type: .system)
    private let saveCurrentScanLabel = UILabel()
    private let fileTypeWarning = UILabel()
    private let fileNameInput = UITextField()
    var mainController: MainController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        mainImage.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainImage)
        
        fileNameInput.delegate = self
        fileNameInput.isUserInteractionEnabled = true
        fileNameInput.translatesAutoresizingMaskIntoConstraints = false
        fileNameInput.placeholder = "File Name"
        fileNameInput.borderStyle = .roundedRect
        fileNameInput.autocorrectionType = .no
        fileNameInput.returnKeyType = .done
        fileNameInput.backgroundColor = .systemBackground
        view.addSubview(fileNameInput)
        
        saveCurrentScanLabel.text = "Current Scan: \(mainController.renderer.highConfCount) points"
        saveCurrentScanLabel.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentScanLabel.textColor = .white
        view.addSubview(saveCurrentScanLabel)
        
        saveCurrentButton.tintColor = .green
        saveCurrentButton.setTitle("Save current scan", for: .normal)
        saveCurrentButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        saveCurrentButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        saveCurrentButton.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentButton.addTarget(self, action: #selector(executeSave), for: .touchUpInside)
        view.addSubview(saveCurrentButton)
        
        NSLayoutConstraint.activate([
            saveCurrentScanLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentScanLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            
            mainImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            mainImage.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 20),
            mainImage.widthAnchor.constraint(equalToConstant: 300),
            mainImage.heightAnchor.constraint(equalToConstant: 300),
            
            fileNameInput.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileNameInput.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            fileNameInput.widthAnchor.constraint(equalToConstant: 250),
            fileNameInput.heightAnchor.constraint(equalToConstant: 45),
            
            saveCurrentButton.widthAnchor.constraint(equalToConstant: 250),
            saveCurrentButton.heightAnchor.constraint(equalToConstant: 100),
            saveCurrentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    /// Text field delegate methods
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { return true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func onSaveError(error: XError) {
        dismissModal()
        mainController.onSaveError(error: error)
    }
        
    func dismissModal() { self.dismiss(animated: true, completion: nil) }
    
    private func beforeSave() {
        saveCurrentButton.isEnabled = false
        isModalInPresentation = true
    }
        
    @objc func executeSave() -> Void {
        let fileName = !fileNameInput.text!.isEmpty ? fileNameInput.text : "untitled"
        let format = selectedFormat
            .lowercased(with: .none)
            .split(separator: " ")
            .joined(separator: "_")
        
        mainController.renderer.saveAsPlyFile(
            fileName: fileName!,
            lastCameraTransform: mainController.renderer.lastCameraTransform,
            afterGlobalThread: [dismissModal, mainController.afterSave],
            errorCallback: onSaveError,
            format: format)
    }
}


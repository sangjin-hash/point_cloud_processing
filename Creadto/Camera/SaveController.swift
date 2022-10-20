//
//  SaveController.swift
//  SceneDepthPointCloud

import SwiftUI
import Foundation

class SaveController : UIViewController, UITextFieldDelegate {
    private var exportData = [URL]()
    private let selectedFormat: String = "Binary Little Endian"
    
    private let mainImage = UIImageView(image: .init(named: "save"))
    private let saveCurrentButton = UIButton(type: .system)
    private let goToExportViewButton = UIButton(type: .system)
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
        saveCurrentButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        saveCurrentButton.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentButton.addTarget(self, action: #selector(executeSave), for: .touchUpInside)
        view.addSubview(saveCurrentButton)
        
        goToExportViewButton.tintColor = .cyan
        goToExportViewButton.setTitle("Previously Saved Scans", for: .normal)
        goToExportViewButton.setImage(.init(systemName: "tray.full"), for: .normal)
        goToExportViewButton.translatesAutoresizingMaskIntoConstraints = false
        goToExportViewButton.addTarget(self, action: #selector(goToExportView), for: .touchUpInside)
        view.addSubview(goToExportViewButton)
        
        NSLayoutConstraint.activate([
            fileNameInput.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileNameInput.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            fileNameInput.widthAnchor.constraint(equalToConstant: 250),
            fileNameInput.heightAnchor.constraint(equalToConstant: 45),
            
            mainImage.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -185),
            mainImage.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 20),
            mainImage.widthAnchor.constraint(equalToConstant: 300),
            mainImage.heightAnchor.constraint(equalToConstant: 300),
            
            saveCurrentScanLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentScanLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            
            saveCurrentButton.widthAnchor.constraint(equalToConstant: 150),
            saveCurrentButton.heightAnchor.constraint(equalToConstant: 50),
            saveCurrentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -165),
            
            goToExportViewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            goToExportViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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
        goToExportViewButton.isEnabled = false
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
            beforeGlobalThread: [beforeSave],
            afterGlobalThread: [dismissModal, mainController.afterSave],
            errorCallback: onSaveError,
            format: format)
    }
    
    @objc func goToExportView() -> Void {
            dismissModal()
            mainController.goToExportView()
        }
}


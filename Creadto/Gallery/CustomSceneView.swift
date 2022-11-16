//
//  CustomSceneView.swift
//  Creadto
//
//  Created by 이상진 on 2022/10/05.
//

import SwiftUI
import SceneKit

struct CustomSceneView: UIViewRepresentable {
    @Binding var scene: SCNScene?
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling2X
        view.scene = scene
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        
    }
    
}

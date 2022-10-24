//
//  MainTabView.swift
//  Creadto
//
//  Created by 이상진 on 2022/09/13.
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedIndex = 1
    
    var body: some View {
            TabView(selection: $selectedIndex) {
                GalleryView()
                    .onTapGesture {
                        self.selectedIndex = 0
                    }
                    .tabItem{
                        VStack(spacing: 4){
                            Image(systemName: "photo")
                            Text("Gallery")
                        }
                    }.tag(0)
                
                CameraController()
                    .onTapGesture {
                        self.selectedIndex = 1
                    }
                    .tabItem{
                        VStack(spacing: 4){
                            Image(systemName: "camera")
                            Text("Camera")
                        }
                    }.tag(1)
                
                ExportView()
                    .onTapGesture {
                        self.selectedIndex = 2
                    }
                    .tabItem{
                        VStack(spacing: 4){
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                    }.tag(2)
            }
        }
    
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

struct CameraController : UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraController>) -> UIViewControllerType {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyBoard.instantiateViewController(identifier: "Camera")
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context:
                                UIViewControllerRepresentableContext<CameraController>){
        
    }
}

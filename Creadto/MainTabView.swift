//
//  MainTabView.swift
//  Creadto
//
//  Created by 이상진 on 2022/09/13.
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedIndex = 1
    @StateObject var fileController = FileController()
    
    var body: some View {
            TabView(selection: $selectedIndex) {
                GalleryView()
                    .environmentObject(fileController)
                    .tabItem{
                        VStack(spacing: 4){
                            Image(systemName: "photo")
                            Text("Gallery")
                        }
                    }.onAppear {
                        self.selectedIndex = 0
                    }.tag(0)
                
                CameraController()
                    .tabItem{
                        VStack(spacing: 4){
                            Image(systemName: "camera")
                            Text("Camera")
                        }
                    }.onAppear {
                        self.selectedIndex = 1
                    }.tag(1)
                
                
                ExportView()
                    .environmentObject(fileController)
                    .tabItem{
                        VStack(spacing: 4){
                            Image(systemName: "square.and.arrow.up")
                            Text("Export")
                        }
                    }.onAppear {
                        self.selectedIndex = 2
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

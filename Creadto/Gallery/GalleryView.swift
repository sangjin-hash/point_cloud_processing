//
//  GalleryView.swift
//  Creadto
//
//  Created by 이상진 on 2022/09/13.
//

import SwiftUI
import SceneKit

struct GalleryView: View {
    private var scnItems = [URL]()
    private var scnFileName = [String]()
    @State private var selectedSCN = 0
    
    init(){
        let docs = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        scnItems = try! FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        scnItems.map{ scnFileName.append(
            $0.path.components(separatedBy: "/").last!
        ) }
    }
    
    var body: some View {
        NavigationView(content: {
            VStack {
                Spacer()
                
                Picker("Choose a .scn file", selection: $selectedSCN){
                    ForEach(0..<scnFileName.count){
                        Text(self.scnFileName[$0])
                    }
                }
                .pickerStyle(.wheel)
                .background(.yellow)
                .cornerRadius(15)
                .padding()
                
                Spacer()
                
                NavigationLink(
                    destination: SceneRenderView(scnPath: scnItems[selectedSCN]),
                    label: {
                        Text("Render")
                    })
                
                Spacer()
                
                }
            })
    }
}

struct SceneRenderView : View {
    
    @State private var scene : SCNScene?
    private var scnFile : URL
    
    init(scnPath : URL) {
        self.scnFile = scnPath
        _scene = State(initialValue: SCNSceneSource(url: scnFile)?.scene()!)
    }
    
    var body : some View {
        VStack{
            NavigationLink(
                destination: GalleryView(),
                label: {}
            )
            
            CustomSceneView(scene: $scene)
                .frame(height:350)
        }
        .padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
    }
}

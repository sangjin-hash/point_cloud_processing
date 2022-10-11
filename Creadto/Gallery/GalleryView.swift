//
//  GalleryView.swift
//  Creadto
//
//  Created by 이상진 on 2022/09/13.
//

import SwiftUI
import SceneKit

struct GalleryView: View {
    @State private var scnItems = [URL]()
    @State private var scnFileName = [String]()
    @State private var selectedSCN = 0
    @State private var isPath : Bool = false
    
    init() {
        refresh()
    }
    
    func refresh() {
        let docs = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        
        scnItems.removeAll()
        scnFileName.removeAll()
        
        scnItems = try! FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        scnItems.map{ scnFileName.append(
            $0.path.components(separatedBy: "/").last!
        ) }
        
        if scnItems.count > 0 {
            isPath = true
        }
    }
    
    
    var body: some View {
        NavigationView(content: {
            VStack {
                Spacer()
                
                Picker("Choose a .scn file", selection: $selectedSCN){
                    ForEach(0..<scnFileName.count, id: \.self){
                        Text(self.scnFileName[$0]).tag($0)
                    }
                }
                .pickerStyle(.wheel)
                .background(.yellow)
                .cornerRadius(15)
                .padding()
                .onAppear{
                    refresh()
                }
                
                Spacer()
                
                if isPath {
                    NavigationLink(
                        destination: SceneRenderView(scnPath: scnItems[selectedSCN]),
                        label: {
                            Text("Render")
                        })
                    
                    
                    Spacer()
                }
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
        ZStack{
            Color.white.ignoresSafeArea()
            VStack{
                NavigationLink(
                    destination: GalleryView(),
                    label: {}
                )
                
                CustomSceneView(scene: $scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
    }
}

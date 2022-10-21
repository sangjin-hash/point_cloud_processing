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
    private let columns = [GridItem(.adaptive(minimum: 150))]
    @State private var  isTapped = false
    @State private var isPath = false
    
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
            ScrollView{
                VStack{
                    Text("Select the file to render").font(.headline).padding(40)
                    
                    Spacer()
                    
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(Array(scnFileName.enumerated()), id:\.element){ index, element in
                            ZStack{
                                Capsule()
                                    .fill(Color.indigo)
                                    .frame(height: 50)
                                Text(element)
                                    .foregroundColor(.white)
                            }.onTapGesture {
                                self.selectedSCN = index
                                isTapped.toggle()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if isPath{
                        NavigationLink("", destination: SceneRenderView(scnPath: scnItems[selectedSCN]),isActive: $isTapped)
                    }
                    
                }
                .onAppear{
                    refresh()
                }
                .navigationBarHidden(true)
                .padding(20)
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

//
//  GalleryView2.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/13.
//

import SwiftUI
import SceneKit

struct GalleryView: View {
    var url: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State var urls : [URL] = []
    @EnvironmentObject var fileController : FileController
    
    var body: some View {
        NavigationView{
            List{
                Section{
                    ForEach(urls, id: \.self){ selectedUrl in
                        NavigationLink(destination: RenderView(selectedUrl: selectedUrl, fileList: fileController.getContentsOfDirectory(url: selectedUrl)), label: {
                            HStack{
                                Text(selectedUrl.lastPathComponent)
                                Spacer()
                            }
                            .frame(height: 50)
                            .contentShape(Rectangle())
                        })
                    }
                    .onDelete(perform: delete)
                }
            }.onAppear{
                urls = fileController.getContentsOfDirectory(url: url)
            }
            .navigationTitle("Gallery")
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    func delete(at offsets: IndexSet) {
        if let first = offsets.first {
            try! FileManager.default.removeItem(at: urls[first])
            urls.remove(at: first)
        }
    }
}

struct RenderView : View {
    @State var selectedUrl : URL
    @State var fileList : [URL]
    @State var isTapped = false
    @EnvironmentObject var fileController : FileController
    
    var body : some View {
        NavigationView{
            List{
                Section{
                    ForEach(fileList, id: \.self){ file in
                        HStack{
                            Text(file.lastPathComponent)
                            Spacer()
                        }
                        .frame(height: 50)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            print(file)
                            self.selectedUrl = file
                            isTapped.toggle()
                        }
                    }
                }
            }
            
        }.navigationBarHidden(true)
        
        if isTapped{
            NavigationLink("", destination: SceneRenderingView(scnPath: selectedUrl), isActive: $isTapped)
        }
    }
}

struct SceneRenderingView : View {

    @State private var scene : SCNScene?
    private var scnFile : URL

    init(scnPath : URL) {
        self.scnFile = scnPath
        _scene = State(initialValue: SCNSceneSource(url: scnFile)?.scene()!)
    }

    var body : some View {
        NavigationView{
            ZStack{
                Color.white.ignoresSafeArea()

                CustomScene2View(scene: $scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

    }
}

struct CustomScene2View: UIViewRepresentable {
    @Binding var scene: SCNScene?
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.antialiasingMode = .multisampling2X
        view.scene = scene
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
}

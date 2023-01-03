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
                    }.onDelete(perform: delete)
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

    private let adaptiveColumns = [
        GridItem(.adaptive(minimum: 170))
    ]

    var body : some View {
        ScrollView{
            LazyVGrid(columns: adaptiveColumns, spacing: 20){
                ForEach(fileList.filter { self.checkSCNFile(fileURL: $0)}, id: \.self){ file in
                    VStack{
                        Image(uiImage: "\(thumbnailImage(file: file))".load())
                            .resizable()
                            .clipShape(Rectangle())
                            .cornerRadius(30)
                            .frame(width: 170, height: 170)

                        Text(file.deletingPathExtension().lastPathComponent)
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.5)
                    }
                    .onTapGesture {
                        self.selectedUrl = file
                        isTapped.toggle()
                    }
                }
            }
        }.onAppear{
            if selectedUrl.hasDirectoryPath {
                fileList = fileController.getContentsOfDirectory(url: selectedUrl)
            }
            else {
                fileList = fileController.getContentsOfDirectory(url: selectedUrl.deletingLastPathComponent())
            }
        }

        if isTapped{
            if selectedUrl.lastPathComponent == "Measurement.json" {
                NavigationLink("", destination: MeasureView(jsonURL: selectedUrl).navigationBarTitle("", displayMode: .inline), isActive: $isTapped)
            }
            else {
                NavigationLink("", destination: SceneRenderingView(scnPath: selectedUrl), isActive: $isTapped)
            }
        }
    }

    func thumbnailImage(file : URL) -> URL {
        let fileName = file.deletingPathExtension().lastPathComponent
        if(fileName == "Measurement") {
            let result = Bundle.main.url(forResource: "Measurement", withExtension: "jpeg")
            return result!
        } else {
            let direction = fileName.components(separatedBy: "_").first!
            let result = file.deletingLastPathComponent().appendingPathComponent("\(direction).png")
            return result
        }
    }

    func checkSCNFile(fileURL : URL) -> Bool {
        if(fileURL.pathExtension == "scn" || fileURL.lastPathComponent == "Measurement.json"){
            return true
        }else{
            return false
        }
    }

    func getFileName(url : URL) -> String {
        let deletedComponent = url.deletingPathExtension()
        let result = deletedComponent.lastPathComponent
        return result
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

                CustomSceneView(scene: $scene)
                    .edgesIgnoringSafeArea(.top)
            }
        }

    }
}

struct MeasureView : UIViewControllerRepresentable {
    typealias UIViewControllerType = MeasureViewController
    let jsonURL : URL
    
    init(jsonURL: URL) {
        self.jsonURL = jsonURL
    }
    
    func makeUIViewController(context: Context) -> MeasureViewController {
        let vc = MeasureViewController(jsonURL: jsonURL)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MeasureViewController, context: Context) {
        
    }
}

extension String {
    func load() -> UIImage {
        do {
            guard let url = URL(string: self) else { return UIImage()}
            let data: Data = try Data(contentsOf: url)
            return UIImage(data: data) ?? UIImage()
        } catch {
            fatalError("Error to load thumbnail Image")
        }
        return UIImage()
    }
}

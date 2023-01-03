//
//  DetailView.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/11.
//

import SwiftUI
import Alamofire
import UniformTypeIdentifiers

struct ConvertView: View {
    private let url: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State private var urls : [URL] = []
    @EnvironmentObject var fileController : FileController
    @StateObject var viewModel = ConvertViewModel()
    
    var body: some View {
        NavigationView{
            List{
                Section{
                    ForEach(urls, id: \.self){ selectedUrl in
                        NavigationLink(destination: FileView(selectedUrl: selectedUrl, fileList: fileController.getContentsOfDirectory(url: selectedUrl)), label: {
                            HStack{
                                Text(selectedUrl.lastPathComponent)
                                Spacer()
                            }
                            .frame(height: 50)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.sendToServer(url: selectedUrl)
                            }
                        })
                    }
                    .onDelete(perform: delete)
                }
            }
            .onAppear{
                urls = fileController.getContentsOfDirectory(url: url)
            } 
            .navigationTitle("Convert")
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func delete(at offsets: IndexSet) {
        if let first = offsets.first {
            try! FileManager.default.removeItem(at: urls[first])
            urls.remove(at: first)
        }
    }
    
}

struct FileView : View {
    @State var selectedUrl : URL
    @State var fileList : [URL]
    @State private var isPresented = false
    @EnvironmentObject var fileController : FileController
    @State var selectedIndex = 0
    
    var body : some View {
        List{
            Section{
                ForEach(Array(fileList.enumerated()), id: \.offset){ index, file in
                    HStack{
                        Text(file.lastPathComponent)
                        Spacer()
                    }.frame(height: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.selectedIndex = index
                        isPresented.toggle()
                    }
                }.onDelete(perform: delete)
            }
        }.onAppear{
            if selectedUrl.hasDirectoryPath {
                fileList = fileController.getContentsOfDirectory(url: selectedUrl)
            }
            else {
                fileList = fileController.getContentsOfDirectory(url: selectedUrl.deletingLastPathComponent())
            }
        }.sheet(isPresented: $isPresented, content: {
            ModalView(activityItems: [fileList[selectedIndex]])
        })
    }
    
    func delete(at offsets: IndexSet) {
        if let first = offsets.first {
            try! FileManager.default.removeItem(at: fileList[first])
            fileList.remove(at: first)
        }
    }
}

struct ModalView: UIViewControllerRepresentable{
    var activityItems: [URL]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ModalView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ModalView>) {}
}

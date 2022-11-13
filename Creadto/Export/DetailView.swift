//
//  DetailView.swift
//  Creadto
//
//  Created by 이상진 on 2022/11/11.
//

import SwiftUI

struct DetailView: View {
    var url: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @State var urls : [URL] = []
    @EnvironmentObject var fileController : FileController
    
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
                        })
                    }
                    .onDelete(perform: delete)
                }
            }.onAppear{
                urls = fileController.getContentsOfDirectory(url: url)
            } 
            .navigationTitle("Export")
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

struct FileView : View {
    var selectedUrl : URL
    @State var fileList : [URL]
    @EnvironmentObject var fileController : FileController
    
    var body : some View {
        List{
            Section{
                ForEach(fileList, id: \.self){ file in
                    Text(file.lastPathComponent)
                }
            }
        }
    }
}

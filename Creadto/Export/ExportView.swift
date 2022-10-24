//
//  ExportView.swift
//  Creadto
//
//  Created by 이상진 on 2022/09/13.
//

import SwiftUI
import UIKit

struct ExportView: View {
    @State private var scnItems = [URL]()
    @State private var scnFileName = [String]()
    
    @State private var selectedSCN = 0
    private let columns = [GridItem(.adaptive(minimum: 150))]
    @State private var isPath : Bool = false
    @State private var isPresented = false
    @State private var isDeleteClicked = false
    
    func refresh() {
        print("refresh 호출")
        let docs = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        
        scnItems.removeAll()
        scnFileName.removeAll()
        
        scnItems = try! FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        scnItems.map{ scnFileName.append(
            $0.path.components(separatedBy: "/").last!)
        }
        
        if scnItems.count > 0 {
            isPath = true
        }
    }
    
    func delete(at offsets: IndexSet) {
        if let first = offsets.first {
            try! FileManager.default.removeItem(at: scnItems[first])
            scnItems.remove(at: first)
            refresh()
        }
      }
    
    var body: some View {
        NavigationView{
            VStack{
                Text("")
                    .navigationBarTitle(Text("Select the file to export"), displayMode: .inline)
                List{
                    ForEach(Array(scnFileName.enumerated()), id: \.offset){ index, element in
                        HStack{
                            Text(element)
                            Spacer()
                        }.frame(height: 50)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.selectedSCN = index
                            isPresented.toggle()
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .onAppear{
                refresh()
            }
            .sheet(isPresented: $isPresented, content: {
                ModalView(activityItems: [scnItems[selectedSCN]])
            })
            .toolbar{
                EditButton()
            }
        }
        
    }
}

struct ModalView: UIViewControllerRepresentable{
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ModalView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ModalView>) {}
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}


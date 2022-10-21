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
            $0.path.components(separatedBy: "/").last!)
        }
        
        if scnItems.count > 0 {
            isPath = true
        }
    }
    
    var body: some View {
        ScrollView{
            VStack{
                HStack{
                    Spacer()
                    
                    Text("Select the file to export").font(.headline)
                    
                    Spacer()
                    
                    if isPath, !isDeleteClicked {
                        Button(action:{
                            self.isDeleteClicked.toggle()
                        }){
                            Image(systemName: "trash")
                                .imageScale(.large)
                        }
                    }
                    
                    if isDeleteClicked {
                        Button(action: {
//                            try! FileManager.default.removeItem(at: scnItems[selectedSCN])
//                            scnItems.remove(at: selectedSCN)
//                            refresh()
                            
                        }){
                            Text("확인")
                        }
                        
                        Button(action: {
                            self.isDeleteClicked.toggle()
                        }){
                            Text("취소")
                        }
                    }
                }.padding(20)
                
                
                Spacer()
                
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(Array(scnFileName.enumerated()), id:\.element){ index, element in
                        ZStack{
                            Capsule()
                                .fill(Color.yellow)
                                .frame(height: 50)
                            Text(element)
                                .foregroundColor(.white)
                        }.onTapGesture {
                            self.selectedSCN = index
                            isPresented.toggle()
                        }
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $isPresented, content: {
                    ModalView(activityItems: [scnItems[selectedSCN]])
                })
                
                
            }
            .onAppear{
                refresh()
            }
            .navigationBarHidden(true)
            .padding(20)
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


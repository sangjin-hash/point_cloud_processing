//
//  DetailsView.swift
//  Creadto
//
//  Created by 이상진 on 2023/01/31.
//

import Foundation
import SwiftUI

struct DetailsView : View {
    
    var body : some View {
        VStack{
            List {
                Section(header: Text("Front").font(.system(size: 32, weight: .bold))) {
                    ForEach(0..<16){ _index in
                        TaskRow(index: _index)
                    }
                }
                .headerProminence(.increased)
                
                Section(header: Text("Side").font(.system(size: 32, weight: .bold))) {
                    ForEach(16..<20){ _index in
                        TaskRow(index: _index)
                    }
                }.headerProminence(.increased)
                
                Section(header: Text("Back").font(.system(size: 32, weight: .bold))) {
                    ForEach(20..<31){ _index in
                        TaskRow(index: _index)
                    }
                }
                .headerProminence(.increased)
            }
        }
    }
}

struct TaskRow : View {
    var index : Int
    
    init(index: Int) {
        self.index = index
    }
    
    var body : some View {
        HStack {
            Text("\(DetailsData.data[index].eng_part)")
                .font(.system(size: 20))
            Spacer()
            Text("\(DetailsData.data[index].value)")
                .font(.system(size: 24))
        }
    }
}

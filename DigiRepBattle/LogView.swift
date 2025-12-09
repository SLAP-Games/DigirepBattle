//
//  LogView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct LogView: View {
    let lines: [String]
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(lines.indices, id: \.self) { i in
                    Text(lines[i]).font(.bestTenCaption)
                }
            }.padding(.horizontal)
        }
        .frame(maxHeight: 200)
        .background(.black.opacity(0.03))
    }
}

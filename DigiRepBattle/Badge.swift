//
//  Badge.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI

struct Badge: View {
    let player: Player
    let active: Bool
    let tint: Color
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name).bold()
                Text("Gold: \(player.gold)")
                    .font(.bestTenCaption)
                Text("TOTAL: \(total)")
                    .font(.bestTenCaption)
            }
        }
        .padding(8)
        .background(active ? .yellow.opacity(0.8) : .white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

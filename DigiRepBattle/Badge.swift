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
    
    private var totalScale: CGFloat {
        total >= 1_000 ? 0.9 : 1.0
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .foregroundStyle(tint)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .bold()
                    .foregroundColor(.white)
                Text("Gold: \(player.gold)G")
                    .font(.bestTenCaption)
                    .foregroundColor(.white)
                Text("TOTAL: \(total)G")
                    .font(.bestTenCaption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .scaleEffect(totalScale, anchor: .leading)
                    .foregroundColor(.white)
            }
        }
        .padding(10)
        .background(
            Image(active ? "playerWindow" : "playerWindow2")
                .resizable()
                .scaledToFill()
        )
    }
}

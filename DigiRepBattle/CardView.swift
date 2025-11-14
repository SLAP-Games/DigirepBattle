//
//  CardView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI

struct CardView: View {
    let card: Card
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .overlay(
                    Image("cardS")
                        .resizable()
                        .scaledToFill()
                )
                .frame(width: 90, height: 130)

            VStack(spacing: 6) {
                Text(card.kind == .spell ? "スペル" : "デジレプ")
                    .font(.caption2)
                    .foregroundStyle(.white)
                Image(card.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            .padding(6)
        }
    }
}

//
//  CardView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI

struct CardView: View {
    let card: Card
    /// 左上に表示する枚数バッジ（nil の場合は非表示）
    var badgeCount: Int? = nil

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
                Text(card.name)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Image("\(card.symbol)1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            .padding(6)

            // 左上バッジ
            if let badgeCount {
                VStack {
                    HStack {
                        Text("\(badgeCount)")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.9))
                            )
                            .foregroundColor(.white)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
    }
}

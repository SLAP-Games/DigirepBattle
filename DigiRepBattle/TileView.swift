//
//  TileView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct TileView: View {
    let index: Int
    let size: CGFloat
    let hasP1: Bool
    let hasP2: Bool
    let owner: Int?
    let level: Int
    let creatureSymbol: String?
    let toll: Int
    let hp: Int?
    let hpMax: Int?

    private var accent: Color {
        switch owner {
        case 0: return .blue
        case 1: return .red
        default: return .secondary
        }
    }

    var body: some View {
        let hpBarWidth = size * 0.82
        let hpBarHeight: CGFloat = 6

        ZStack {
            // タイル本体
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(owner == nil ? .secondary.opacity(0.8) : accent,
                                lineWidth: owner == nil ? 1 : 3)
                )
                .frame(width: size, height: size)

            // マス番号
            VStack(spacing: 2) {
                Text("\(index + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // クリーチャー（中央）
            if let sym = creatureSymbol, level > 0 {
                Image(systemName: sym)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(accent)
            }

            // 下部：HPバー + Lv/通行料
            VStack(spacing: 4) {
                Spacer()

                if let hp = hp, let hpMax = hpMax, hpMax > 0, level > 0 {
                    let ratio = max(0, min(1, CGFloat(hp) / CGFloat(hpMax)))

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.22))
                            .frame(width: hpBarWidth, height: hpBarHeight)
                        Capsule()
                            .fill(Color.green)
                            .frame(width: hpBarWidth * ratio, height: hpBarHeight)
                            .animation(.easeInOut(duration: 0.25), value: ratio)
                    }
                    .frame(height: hpBarHeight + 4)
                    .padding(.horizontal, size * 0.09)
                    .padding(.bottom, size * 0.08)
                }

                if level > 0 {
                    HStack {
                        Text("Lv \(level)")
                            .font(.caption2).bold()
                            .foregroundStyle(accent)
                        Spacer()
                        Text("\(toll)")
                            .font(.caption2).bold()
                            .foregroundStyle(accent)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
                }
            }
            .frame(width: size, height: size)
        }
        // ← ここがポイント：overlay で四隅に固定
        .overlay(alignment: .topLeading) {
            if hasP1 {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.blue)
                    .padding(6)
                    .background(.thinMaterial, in: Circle())
                    .padding(6) // タイル端からの余白
            }
        }
        .overlay(alignment: .topTrailing) {
            if hasP2 {
                Image(systemName: "person.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.red)
                    .padding(6)
                    .background(.thinMaterial, in: Circle())
                    .padding(6)
            }
        }
    }
}

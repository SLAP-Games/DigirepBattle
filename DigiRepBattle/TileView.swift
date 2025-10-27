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

    // 占領表示用
    let owner: Int?            // nil / 0 / 1
    let level: Int             // 0.. (0は未設置)
    let creatureSymbol: String?
    let toll: Int

    private var accent: Color {
        switch owner {
        case 0: return .blue
        case 1: return .red
        default: return .secondary
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(owner == nil ? .secondary.opacity(0.8) : accent, lineWidth: owner == nil ? 1 : 3)
                )
                .frame(width: size, height: size)
                .contentShape(RoundedRectangle(cornerRadius: 14))

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

            // 左上：P1 / 右上：P2
            HStack {
                if hasP1 {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.blue)
                        .padding(4)
                        .background(.thinMaterial, in: Circle())
                } else { Color.clear.frame(width: 0) }
                Spacer()
                if hasP2 {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                        .padding(4)
                        .background(.thinMaterial, in: Circle())
                } else { Color.clear.frame(width: 0) }
            }
            .padding(6)
            .frame(width: size, height: size, alignment: .top)

            // 左下：Lv / 右下：通行料
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
                .frame(width: size, height: size, alignment: .bottom)
            }
        }
    }
}

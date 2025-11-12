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
    let bgImageName: String?          // 例: "field", "desert", "town" など（拡張子不要）
    let attribute: TileAttribute?      // 表示には未使用（今後の判定用）
    let highlightTargets: Set<Int>
    
    private var special: SpecialNodeKind? { specialNodeKind(for: index) }
    private var isPlaceable: Bool { !isSpecialNode(index) }   // クリーチャー設置可否
    private var accent: Color {
        switch owner {
        case 0: return .blue
        case 1: return .red
        default: return .secondary
        }
    }

    var body: some View {
        let hpBarWidth = size * 0.5
        let hpBarHeight: CGFloat = 6

        ZStack {
            // タイル本体
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.clear)
                .background(
                    Group {
                        if let bg = bgImageName {
                            Image(bg)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.white
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(owner == nil ? .secondary.opacity(0.8) : accent,
                                lineWidth: owner == nil ? 1 : 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow, lineWidth: highlightTargets.contains(index) ? 4 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.yellow.opacity(highlightTargets.contains(index) ? 0.18 : 0))
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
                ZStack {
                    Image(sym)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .compositingGroup()
                        .shadow(color: accent.opacity(1), radius: 2, x: 0, y: 0)
                        .shadow(color: accent.opacity(0.8), radius: 4, x: 0, y: 0)
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
                        .padding(.bottom, size * 0.3)
                    }
                }
            }

            // 下部：HPバー + Lv/通行料
            VStack(spacing: 4) {
                Spacer()

                if level > 0 {
                    HStack {
                        Text("Lv \(level)")
                            .font(.caption2).bold()
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(toll)")
                            .font(.caption2).bold()
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 4)
                }
            }
            .frame(width: size, height: size)
        }
        .overlay(
            // === 追加: 特別マスの建物画像 ===
            Group {
                if let special {
                    switch special {
                    case .castle:
                        Image("castle") // Assetsに castle.png を登録
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.76, height: size * 0.76)
                    case .tower:
                        Image("tower") // Assetsに tower.png を登録
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 0.72, height: size * 0.72)
                    }
                }
            }
        )
    }
}

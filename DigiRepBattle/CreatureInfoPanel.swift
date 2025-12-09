//
//  CreatureInfoPanel.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//

import SwiftUI

struct CreatureInfoPanel: View {
    let iv: CreatureInspectView
    let onClose: () -> Void

    var ownerLabel: String {
        iv.owner == 0 ? "You" : "CPU"
    }

    var body: some View {
        VStack(spacing: 10) {
            // ヘッダ：マップ情報
            HStack {
                HStack(spacing: 8) {
                    Image(iv.mapImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.4)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("タイル \(iv.tileIndex)")
                            .font(.bestTenSubheadline).fontWeight(.semibold)
                        Text("属性: \(iv.mapAttribute)")
                            .font(.bestTenCaption).foregroundStyle(.secondary)
                        Text("レベル: Lv\(iv.tileLevel)")
                            .font(.bestTenCaption).foregroundStyle(.secondary)
                        Text("状態: \(iv.tileStatus)")
                            .font(.bestTenCaption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.bestTenTitle3)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // クリーチャー行
            HStack(alignment: .top, spacing: 12) {
                Image(iv.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.3)))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(ownerLabel).font(.bestTenHeadline)
                        Spacer()
                        Text("HP \(iv.hpText)")
                            .font(.bestTenSubheadline)
                            .monospacedDigit()
                    }

                    // ステータス（敵は"不明"）
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                        GridRow { Text("なつき度"); Text(iv.affection) }
                        GridRow { Text("戦闘力");   Text(iv.power) }
                        GridRow { Text("耐久力");   Text(iv.durability) }
                        GridRow { Text("乾耐性");   Text(iv.dryRes) }
                        GridRow { Text("水耐性");   Text(iv.waterRes) }
                        GridRow { Text("熱耐性");   Text(iv.heatRes) }
                        GridRow { Text("冷耐性");   Text(iv.coldRes) }
                    }
                    .font(.bestTenCaption)
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8, y: 4)
        )
        .frame(maxWidth: 460, alignment: .topLeading)
    }
}

//
//  PurchaseSpellSheetView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//

import SwiftUI
import UIKit

struct PurchaseSpellSheetView: View {
    @ObservedObject var vm: GameVM

    var body: some View {
        VStack(spacing: 12) {
            Text("スペルショップ")
                .font(.headline)

            // ★ スクロール可能なリスト
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(ShopSpell.catalog) { sp in
                        HStack {
                            // 左：画像（なければ SF Symbol）
                            spellImageView(for: sp)

                            // 中央：名前＆価格
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sp.name)
                                    .font(.subheadline.weight(.semibold))
                                Text("価格 \(sp.price)G")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // 右：購入ボタン
                            Button("購入 (\(sp.price)G)") {
                                vm.openShopSpellDetail(sp)
                            }
                            .disabled(vm.players[vm.turn].gold < sp.price)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            // ★ 高さ制限：必要に応じて値を調整してください
            .frame(maxHeight: 260)

            Divider()

            Button("閉じる") {
                vm.activeSpecialSheet = nil
                vm.specialPending = nil
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - 画像ヘルパー

    /// sp-dice1 → dice1 などに変換
    private func imageName(for spell: ShopSpell) -> String {
        if spell.id.hasPrefix("sp-") {
            return String(spell.id.dropFirst(3))
        } else {
            return spell.id
        }
    }

    /// 画像が存在すればそれを、なければ SF Symbol を返す
    @ViewBuilder
    private func spellImageView(for spell: ShopSpell) -> some View {
        let name = imageName(for: spell)

        if UIImage(named: name) != nil {
            // アセットがある場合
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding(.trailing, 4)
        } else {
            // フォールバックの SF Symbol
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(.secondary)
                .padding(.trailing, 4)
        }
    }
}

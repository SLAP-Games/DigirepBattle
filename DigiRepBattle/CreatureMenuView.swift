//
//  CreatureMenuView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI

struct CreatureMenuView: View {
    @ObservedObject var vm: GameVM
    let tile: Int
    let selectedCard: Card
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダー
            HStack {
                Text("自軍領地メニュー").font(.headline)
                Spacer()
                Button("閉じる", action: onClose).buttonStyle(.bordered)
            }

            // メニュー（レベルアップ / 即時交換）
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // レベルアップ（既存のまま）
                    if vm.level.indices.contains(tile),
                       vm.level[tile] >= 1, vm.level[tile] < 5 {
                        let nextLv = vm.level[tile] + 1
                        let need   = vm.levelUpCost[nextLv] ?? 0
                        Button {
                            vm.confirmLevelUp(tile: tile, to: nextLv)
                        } label: {
                            VStack(spacing: 4) {
                                Text("レベルアップ").bold()
                                Text("→ Lv.\(nextLv)（\(need)G）")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(vm.players[vm.turn].gold < need)
                        .buttonStyle(.borderedProminent)
                    }

                    // ★ 即時交換（選択カードAのコストを表示）
                    let cost = selectedCard.stats?.cost ?? 0
                    Button {
                        vm.requestImmediateSwap(forSelectedCard: selectedCard)
                    } label: {
                        VStack(spacing: 4) {
                            Text("デジレプ交換").bold()
                            Text("\(cost)G")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!vm.canSwapCreature(withHandIndex:
                        (vm.hands[vm.turn].firstIndex(of: selectedCard) ?? -1)
                    ))
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


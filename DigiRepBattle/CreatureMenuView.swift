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
    let onChangeCreature: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("自分の領地です")
                .font(.subheadline).bold()

            HStack(spacing: 12) {
                Button("マスレベルアップ") {
                    vm.actionLevelUpOnMyTile()
                }
                .buttonStyle(.borderedProminent)

                Button("クリーチャー交換") {
                    onChangeCreature()           // ★ここで交換モードへ
                }
                .buttonStyle(.bordered)

                Button("終了") {
                    onClose()
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
    }
}


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
            Text("自軍の領地です")
                .font(.bestTenSubheadline).bold()

            HStack(spacing: 12) {
                Button("土地強化") {
                    vm.actionLevelUpOnMyTile(closeMenus: false)
                }
                .buttonStyle(.borderedProminent)

                Button("デジレプ交換") {
                    onChangeCreature()           // ★ここで交換モードへ
                }
                .buttonStyle(.borderedProminent)

                Button("終了") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
    }
}

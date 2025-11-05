//
//  MoveCreatureSheetView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//

import SwiftUI

struct MoveCreatureSheetView: View {
    @ObservedObject var vm: GameVM
    let fromTile: Int

    var emptyTiles: [Int] {
        (0..<vm.tileCount).filter { idx in
            vm.owner.indices.contains(idx) && vm.owner[idx] == nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("移動先を選択").font(.headline)
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 80))]) {
                    ForEach(emptyTiles, id: \.self) { idx in
                        Button("移動する") {
                            vm.confirmMoveCreature(from: fromTile, to: idx)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            Button("閉じる") {
                vm.activeSpecialSheet = nil
                vm.specialPending = nil
            }
        }
        .padding()
    }
}

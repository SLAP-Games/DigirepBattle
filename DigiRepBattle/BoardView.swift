//
//  BoardView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct BoardView: View {
    @StateObject private var vm = GameVM()
    
    var body: some View {
        RingBoardView(p1Pos: vm.players[0].pos,
                      p2Pos: vm.players[1].pos,
                      owner: vm.owner,
                      level: vm.level,
                      creatureSymbol: vm.creatureSymbol,
                      toll: vm.toll,
                      hp: vm.hp,
                      hpMax: vm.hpMax,
                      branchSource: vm.branchSource,
                      branchCandidates: vm.branchCandidates,
                      onPickBranch: { vm.pickBranch($0) },
                      focusTile: vm.focusTile
        )
    }
}

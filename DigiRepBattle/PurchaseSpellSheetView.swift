//
//  PurchaseSpellSheetView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/02.
//

import SwiftUI

struct PurchaseSpellSheetView: View {
    @ObservedObject var vm: GameVM

    var body: some View {
        VStack(spacing: 12) {
            Text("スペルショップ").font(.headline)
            ForEach(ShopSpell.catalog) { sp in
                HStack {
                    VStack(alignment: .leading) {
                        Text(sp.name).font(.subheadline)
                        Text("\(sp.price)G").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("購入") { vm.confirmPurchaseSpell(sp) }
                        .disabled(vm.players[vm.turn].gold < sp.price)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
            Button("閉じる") {
                vm.activeSpecialSheet = nil
                vm.specialPending = nil
            }
        }
        .padding()
    }
}

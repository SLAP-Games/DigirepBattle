//
//  DigiRepBattleApp.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

//  DigiRepBattleApp.swift

import SwiftUI
import CoreData

@main
struct DigiRepBattleApp: App {
    var body: some Scene {
        WindowGroup {
            RootDeckBuilderScreen()
                .ignoresSafeArea()
                .environment(\.font, .bestTen(style: .body))
        }
    }
}

/// デッキ編成 → バトル画面 へのルート
struct RootDeckBuilderScreen: View {
    @State private var selectedDeck: DeckList? = nil
    @State private var selectedDifficulty: BattleDifficulty = .intermediate
    @State private var collection: CardCollection = {
        var c = CardCollection()

        // ★ ここで初期所持カードを設定
        c.add("cre-defaultLizard", count: 6)
        c.add("cre-defaultCrocodile", count: 6)
        c.add("cre-defaultTurtle", count: 6)
        c.add("cre-defaultBeardedDragon", count: 6)
        c.add("cre-defaultHornedFrog", count: 6)
        c.add("cre-defaultGreenIguana", count: 5)
        c.add("cre-defaultBallPython", count: 5)

        c.add("sp-dice1", count: 2)
        c.add("sp-dice2", count: 2)
        c.add("sp-dice3", count: 2)
        c.add("sp-dice4", count: 2)
        c.add("sp-dice5", count: 2)
        c.add("sp-dice6", count: 2)
        c.add("sp-doubleDice", count: 2)
        c.add("sp-firstStrike", count: 2)
        c.add("sp-hardFang", count: 2)
        c.add("sp-hardScale", count: 2)
        c.add("sp-draw2", count: 2)
        c.add("sp-bigScale", count: 2)
        c.add("sp-deleteHand", count: 2)
        c.add("sp-elixir", count: 2)
        c.add("sp-harvest", count: 2)
        c.add("sp-greatStorm", count: 2)
        c.add("sp-snowMountain", count: 2)
        c.add("sp-desert", count: 2)
        c.add("sp-volcano", count: 2)
        c.add("sp-jungle", count: 2)

        return c
    }()

    var body: some View {
        NavigationStack {
            DeckBuilderView(collection: collection) { selectedDeck, difficulty in
                self.selectedDeck = selectedDeck
                self.selectedDifficulty = difficulty
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedDeck != nil },
                set: { presented in
                    if !presented {
                        selectedDeck = nil
                    }
                }
            )) {
                if let deck = selectedDeck {
                    ContentView(onBattleEnded: {
                        selectedDeck = nil
                    })
                    .environmentObject(GameVM(selectedDeck: deck, difficulty: selectedDifficulty))
                }
            }
        }
    }
}

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
        }
    }
}

/// デッキ編成 → バトル画面 へのルート
struct RootDeckBuilderScreen: View {
    @State private var selectedDeck: DeckList? = nil
    @State private var collection: CardCollection = {
        var c = CardCollection()

        // ★ ここで初期所持カードを設定
        c.add("cre-defaultLizard", count: 35)
        c.add("cre-defaultCrocodile", count: 35)
        c.add("cre-defaultTurtle", count: 35)
        c.add("cre-defaultBeardedDragon", count: 35)
        c.add("cre-defaultHornedFrog", count: 35)
        c.add("cre-defaultGreenIguana", count: 35)
        c.add("cre-defaultBallPython", count: 35)

        c.add("sp-dice1", count: 35)
        c.add("sp-dice2", count: 35)
        c.add("sp-dice3", count: 35)
        c.add("sp-dice4", count: 35)
        c.add("sp-dice5", count: 35)
        c.add("sp-dice6", count: 35)
        c.add("sp-doubleDice", count: 35)
        c.add("sp-firstStrike", count: 35)
        c.add("sp-hardFang", count: 35)
        c.add("sp-sharpFang", count: 35)
        c.add("sp-poisonFang", count: 35)
        c.add("sp-hardScale", count: 35)
        c.add("sp-draw2", count: 35)
        c.add("sp-bigScale", count: 35)
        c.add("sp-deleteHand", count: 35)
        c.add("sp-elixir", count: 35)
        c.add("sp-decay", count: 35)

        return c
    }()

    var body: some View {
        NavigationStack {
            DeckBuilderView(collection: collection) { selectedDeck in
                self.selectedDeck = selectedDeck
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedDeck != nil },
                set: { _ in }
            )) {
                if let deck = selectedDeck {
                    ContentView()
                        .environmentObject(GameVM(selectedDeck: deck))
                }
            }
        }
    }
}

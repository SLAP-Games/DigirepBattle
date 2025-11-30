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
        c.add("cre-defaultLizard", count: 30)
        c.add("cre-defaultCrocodile", count: 30)
        c.add("cre-defaultTurtle", count: 30)
        c.add("cre-defaultBeardedDragon", count: 30)
        c.add("cre-defaultHornedFrog", count: 30)
        c.add("cre-defaultGreenIguana", count: 30)
        c.add("cre-defaultBallPython", count: 30)

        c.add("sp-dice1", count: 3)
        c.add("sp-dice2", count: 3)
        c.add("sp-dice3", count: 3)
        c.add("sp-dice4", count: 3)
        c.add("sp-dice5", count: 3)
        c.add("sp-dice6", count: 3)
        c.add("sp-doubleDice", count: 3)
        c.add("sp-firstStrike", count: 3)
        c.add("sp-hardFang", count: 3)
        c.add("sp-sharpFang", count: 3)
        c.add("sp-poisonFang", count: 3)
        c.add("sp-hardScale", count: 3)
        c.add("sp-draw2", count: 3)
        c.add("sp-bigScale", count: 3)
        c.add("sp-deleteHand", count: 3)
        c.add("sp-elixir", count: 3)
        c.add("sp-decay", count: 3)

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

#Preview {
    RootDeckBuilderScreen()
}

//
//  Preview.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/12/03.
//
import SwiftUI

#Preview {
    DeckBuilderView(collection: CardCollection(), onStartBattle: { _ in })
}

#Preview {
    RootDeckBuilderScreen()
}

#Preview {
    ContentView()
        .environmentObject(GameVM(selectedDeck: .previewSample))
}

#Preview("Heal") {
    SpellEffectPreviewView(kind: .heal)
        .frame(width: 300, height: 300)
}

//#Preview("Damage") {
//    SpellEffectPreviewView(kind: .damage)
//        .frame(width: 300, height: 300)
//}
//
//#Preview("Buff") {
//    SpellEffectPreviewView(kind: .buff)
//        .frame(width: 300, height: 300)
//}
//
//#Preview("Debuff") {
//    SpellEffectPreviewView(kind: .debuff)
//        .frame(width: 300, height: 300)
//}

#Preview("Poison") {
    SpellEffectPreviewView(kind: .poison)
        .frame(width: 300, height: 300)
}

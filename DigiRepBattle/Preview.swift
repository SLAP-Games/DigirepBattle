//
//  Preview.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/12/03.
//
import SwiftUI

//#Preview {
//    DeckBuilderView(collection: CardCollection(), onStartBattle: { _ in })
//}
//
//#Preview {
//    RootDeckBuilderScreen()
//}
//
#Preview("メイン") {
    ContentView()
        .environmentObject(GameVM(selectedDeck: .previewSample))
}

#Preview("グリッチ") {
    ZStack {
        Color.black
            .ignoresSafeArea()

        DiceGlitchView(number: 1, duration: 2.0) {
            // プレビューでは何もしない
            print("finished")
        }
        .frame(width: 200, height: 200)
    }
}

#Preview("Heal") {
    SpellEffectPreviewView(kind: .heal)
        .frame(width: 300, height: 300)
}

#Preview("decay") {
    SpellEffectPreviewView(kind: .decay)
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
//
//#Preview("Poison") {
//    SpellEffectPreviewView(kind: .poison)
//        .frame(width: 300, height: 300)
//}

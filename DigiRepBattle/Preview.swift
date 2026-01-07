//
//  Preview.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/12/03.
//
import SwiftUI

//#Preview {
//    DeckBuilderView(collection: CardCollection(), onStartBattle: { _, _ in })
//}

#Preview("メイン") {
    ContentView()
        .environmentObject(GameVM(selectedDeck: .previewSample, difficulty: .advanced))
}

#Preview("Heal") {
    SpellEffectPreviewView(kind: .heal)
        .frame(width: 300, height: 300)
}

//
//  SpellEffectOverlayView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/30.
//

import SwiftUI
import SpriteKit

struct SpellEffectPreviewView: View {

    let kind: SpellEffectScene.EffectKind

    /// このIDを変えることで SpriteView が作り直されて、エフェクト再生がリセットされる
    @State private var replayID = UUID()

    var body: some View {
        ZStack {
            // 背景（お好みで調整）
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            SpriteView(scene: makeScene())
                .id(replayID) // ← IDを変えると再生成される
        }
        .overlay(alignment: .bottom) {
            HStack {
                Text(labelText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                Button("Replay") {
                    // ID を変えると makeScene() が再度呼ばれ、アニメ再生がやり直しになる
                    replayID = UUID()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var labelText: String {
        switch kind {
        case .heal:   return "Heal Effect"
        case .damage: return "Damage Effect"
        case .buff:   return "Buff Effect"
        case .debuff: return "Debuff Effect"
        case .poison: return "Poison Effect"
        }
    }

    private func makeScene() -> SKScene {
        // プレビュー用に固定サイズ。SpriteView側の frame と合わせておけばOK
        let size = CGSize(width: 400, height: 400)
        let scene = SpellEffectScene(size: size, kind: kind)
        scene.onPlaySound = { kind in
            SoundManager.shared.playEffect(for: kind)
        }
        return scene
    }
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

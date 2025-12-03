//
//  SpellEffectTileOverlay.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/30.
//

import SwiftUI
import SpriteKit

// === 各タイルに載せる SpellEffect 用の小さな View
struct SpellEffectTileOverlay: View {
    let size: CGFloat
    let kind: SpellEffectScene.EffectKind

    @State private var scene: SpellEffectScene

    init(size: CGFloat, kind: SpellEffectScene.EffectKind) {
        self.size = size
        self.kind = kind
        let s = SpellEffectScene(
            size: CGSize(width: size, height: size),
            kind: kind
        )
        s.onPlaySound = { kind in
            SoundManager.shared.playEffect(for: kind)
        }

        _scene = State(initialValue: s)
    }
    
    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: size, height: size)
            .allowsHitTesting(false)
    }
}

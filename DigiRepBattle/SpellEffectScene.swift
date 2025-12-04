//
//  SpellEffectScene.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/30.
//

import SpriteKit

final class SpellEffectScene: SKScene {
    
    /// エフェクトの種類
    enum EffectKind: CaseIterable {
        case heal
        case damage
        case buff
        case debuff
        case poison
        case decay
        case devastation
    }
    
    /// 再生完了時に呼ばれる（プレビューでは無視してもOK）
    var onFinished: (() -> Void)?
    var onPlaySound: ((EffectKind) -> Void)?
    
    private let kind: EffectKind
    
    init(size: CGSize, kind: EffectKind) {
        self.kind = kind
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func didMove(to view: SKView) {
        onPlaySound?(kind)
        runEffect()
    }
    
    private func runEffect() {
        switch kind {
        case .heal:   runHealEffect()
        case .damage: runDamageEffect()
        case .buff:   runBuffEffect()
        case .debuff: runDebuffEffect()
        case .poison: runPoisonEffect()
        case .decay:  runDecayEffect()
        case .devastation: runDevastationEffect()
        }
    }
    
    // MARK: - 各エフェクト
    
    private func runHealEffect() {
        let unit = min(size.width, size.height)
        
        // ============================
        // 1) 発生源の楕円（揺らぎなし・拡大しながらフェードアウト）
        // ============================
        let baseWidth: CGFloat = min(size.width * 0.9, 120)
        let baseHeight: CGFloat = min(unit * 0.3, 26)
        
        let baseEllipse = SKShapeNode(ellipseOf: CGSize(width: baseWidth, height: baseHeight))
        baseEllipse.position = CGPoint(x: size.width / 2,
                                       y: unit * 0.2)
        baseEllipse.fillColor = UIColor.yellow.withAlphaComponent(0.25)
        baseEllipse.strokeColor = UIColor.yellow.withAlphaComponent(0.6)
        baseEllipse.lineWidth = 1.0
        baseEllipse.glowWidth = 4.0
        baseEllipse.zPosition = 8
        baseEllipse.alpha = 0.0
        addChild(baseEllipse)
        
        // → ふわっと現れて、そのまま大きくなりながら消える
        let baseAnim = SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)  // スタートを0.8にするので 1.0 まで
            ]),
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            .removeFromParent()
        ])
        baseEllipse.setScale(0.8)
        baseEllipse.run(baseAnim)
        
        // ============================
        // 2) 星パーティクル（楕円から湧き出て上へ）
        // ============================
        let emitter = SKEmitterNode()
        
        // 星のテクスチャ（Assets に "effectStar" を追加しておく）
        emitter.particleTexture = SKTexture(imageNamed: "effectStar")
        
        // 発生位置：楕円の中心から
        emitter.position = baseEllipse.position
        
        // 楕円の幅くらいの範囲から出す
        emitter.particlePositionRange = CGVector(dx: baseWidth * 0.5,
                                                 dy: unit * 0.05)
        // パーティクルの発生量・寿命
        emitter.particleBirthRate = 45
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.4
        
        // 上方向へふわっと
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 10
        emitter.particleSpeed = 110
        emitter.particleSpeedRange = 40
        emitter.yAcceleration = 0
        
        // 見た目
        let scaleFactor = min(size.width, 120) / 120.0
        emitter.particleScale = 0.18 * scaleFactor
        emitter.particleScaleRange = 0.06 * scaleFactor
        emitter.particleScaleSpeed = -0.12 * scaleFactor
        
        emitter.particleColor = .yellow
        emitter.particleColorBlendFactor = 1.0
        
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.0
        emitter.particleAlphaSpeed = -0.8
        
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 2.0
        
        emitter.zPosition = 10
        addChild(emitter)
        
        // 一定時間だけ湧き出させて、その後じわっと消える
        let emitDuration: TimeInterval = 0.8
        let sequence = SKAction.sequence([
            .wait(forDuration: emitDuration),
            .run { emitter.particleBirthRate = 0 },
            .wait(forDuration: 1.0),
            .removeFromParent(),
            .run { [weak self] in
                self?.onFinished?()
            }
        ])
        emitter.run(sequence)
    }
    
    private func runDamageEffect() {
        let radius: CGFloat = 50
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.lineWidth = 6
        node.strokeColor = .red
        node.glowWidth = 12
        addChild(node)
        
        let scaleUp = SKAction.scale(to: 1.6, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.9, duration: 0.1)
        let shake = SKAction.sequence([scaleUp, scaleDown])
        let shakeRepeat = SKAction.repeat(shake, count: 3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        
        let seq = SKAction.sequence([
            shakeRepeat,
            fadeOut,
            .removeFromParent(),
            .run { [weak self] in self?.onFinished?() }
        ])
        
        node.run(seq)
    }
    
    private func runBuffEffect() {
        // BuffEffect.sks があればそれを使う。なければシンプルな黄色丸
        if let emitter = SKEmitterNode(fileNamed: "BuffEffect.sks") {
            emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(emitter)
            
            let wait = SKAction.wait(forDuration: 0.8)
            let seq = SKAction.sequence([
                wait,
                .run { emitter.particleBirthRate = 0 },
                .wait(forDuration: 0.5),
                .removeFromParent(),
                .run { [weak self] in self?.onFinished?() }
            ])
            emitter.run(seq)
        } else {
            let radius: CGFloat = 40
            let node = SKShapeNode(circleOfRadius: radius)
            node.position = CGPoint(x: size.width / 2, y: size.height / 2)
            node.lineWidth = 3
            node.strokeColor = .yellow
            node.glowWidth = 8
            addChild(node)
            
            let scaleUp = SKAction.scale(to: 1.4, duration: 0.3)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            
            let seq = SKAction.sequence([
                scaleUp,
                fadeOut,
                .removeFromParent(),
                .run { [weak self] in self?.onFinished?() }
            ])
            node.run(seq)
        }
    }
    
    private func runDebuffEffect() {
        let radius: CGFloat = 55
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.lineWidth = 4
        node.strokeColor = .purple
        node.glowWidth = 10
        addChild(node)
        
        let rotate = SKAction.rotate(byAngle: .pi, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        
        let seq = SKAction.sequence([
            rotate,
            fadeOut,
            .removeFromParent(),
            .run { [weak self] in self?.onFinished?() }
        ])
        node.run(seq)
    }
    
    private func runPoisonEffect() {
        let unit = min(size.width, size.height)
        
        // 1) 足元の紫＋緑の円
        let baseRadius: CGFloat = min(unit * 0.2, 40)
        let baseCircle = SKShapeNode(circleOfRadius: baseRadius)
        baseCircle.position = CGPoint(x: size.width / 2,
                                      y: unit * 0.2)
        baseCircle.fillColor  = UIColor.purple.withAlphaComponent(0.45)
        baseCircle.strokeColor = UIColor.green.withAlphaComponent(0.9)
        baseCircle.glowWidth  = 8
        baseCircle.lineWidth  = 3
        baseCircle.alpha = 0.0
        baseCircle.zPosition = 8
        addChild(baseCircle)
        
        let baseAnim = SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.12),
                SKAction.scale(to: 1.05, duration: 0.12)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            .removeFromParent()
        ])
        baseCircle.setScale(0.7)
        baseCircle.run(baseAnim)
        
        // 2) 毒の煙（緑色パーティクル）
        let emitter = SKEmitterNode()
        
        // 特に専用テクスチャがなければ heal と同じ "effectStar" を流用
        emitter.particleTexture = SKTexture(imageNamed: "effectStar")
        
        emitter.position = baseCircle.position
        emitter.particlePositionRange = CGVector(dx: baseRadius * 1.2,
                                                 dy: unit * 0.08)
        
        emitter.particleBirthRate = 55
        emitter.particleLifetime = 1.3
        emitter.particleLifetimeRange = 0.4
        
        // 全方向にふわっと広がる煙
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 30
        emitter.yAcceleration = 10
        
        let scaleFactor = min(size.width, 120) / 120.0
        emitter.particleScale = 0.16 * scaleFactor
        emitter.particleScaleRange = 0.05 * scaleFactor
        emitter.particleScaleSpeed = -0.10 * scaleFactor
        
        emitter.particleColor = .purple
        emitter.particleColorBlendFactor = 1.0
        
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -0.7
        
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 1.5
        
        emitter.zPosition = 10
        addChild(emitter)
        
        let seq = SKAction.sequence([
            .wait(forDuration: 0.7),
            .run { emitter.particleBirthRate = 0 },
            .wait(forDuration: 0.6),
            .removeFromParent(),
            .run { [weak self] in
                self?.onFinished?()
            }
        ])
        emitter.run(seq)
    }
    
    private func runDecayEffect() {
        let unit = min(size.width, size.height)
        
        // ============================
        // 1) 紫の楕円：広がりながらフェードアウト
        // ============================
        let baseWidth: CGFloat  = min(size.width * 0.9, 120)
        let baseHeight: CGFloat = min(unit * 0.3, 26)
        
        let ellipse = SKShapeNode(ellipseOf: CGSize(width: baseWidth, height: baseHeight))
        ellipse.position = CGPoint(
            x: size.width / 2,
            y: unit * 0.2
        )
        ellipse.fillColor   = UIColor.systemPurple.withAlphaComponent(0.35)
        ellipse.strokeColor = UIColor.systemPurple.withAlphaComponent(0.8)
        ellipse.lineWidth   = 1.0
        ellipse.glowWidth   = 4.0
        ellipse.zPosition   = 8
        ellipse.alpha       = 0.0
        addChild(ellipse)
        
        let ellipseAnim = SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.08)   // 初期スケール 0.8 → 1.0
            ]),
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            .removeFromParent()
        ])
        ellipse.setScale(0.8)
        ellipse.run(ellipseAnim)
        
        // ============================
        // 2) 濃い紫の下向き矢印：上から下へ落ちながらフェードアウト
        // ============================
        let shaftWidth  = unit * 0.12
        let shaftHeight = unit * 0.24
        let headHeight  = unit * 0.18
        
        let path = CGMutablePath()
        
        // 柄（縦の棒）
        path.move(to: CGPoint(x: -shaftWidth / 2, y: headHeight / 2))
        path.addLine(to: CGPoint(x:  shaftWidth / 2, y: headHeight / 2))
        path.addLine(to: CGPoint(x:  shaftWidth / 2, y: headHeight / 2 + shaftHeight))
        path.addLine(to: CGPoint(x: -shaftWidth / 2, y: headHeight / 2 + shaftHeight))
        path.closeSubpath()
        
        // 矢印の先（三角形）
        path.move(to: CGPoint(x: 0,             y: -headHeight / 2))
        path.addLine(to: CGPoint(x: -shaftWidth, y:  headHeight / 2))
        path.addLine(to: CGPoint(x:  shaftWidth, y:  headHeight / 2))
        path.closeSubpath()
        
        let arrow = SKShapeNode(path: path)
        arrow.fillColor   = UIColor(red: 0.25, green: 0.0, blue: 0.35, alpha: 1.0) // 濃い紫
        arrow.strokeColor = UIColor.black.withAlphaComponent(0.4)
        arrow.lineWidth   = 1.5
        arrow.glowWidth   = 6.0
        arrow.zPosition   = 10
        arrow.alpha       = 0.0
        
        // 画面上側から出て下に落ちるイメージ
        arrow.position = CGPoint(
            x: size.width / 2,
            y: size.height * 0.75
        )
        addChild(arrow)
        
        let moveDown = SKAction.moveBy(x: 0, y: -unit * 0.35, duration: 0.35)
        let fadeIn   = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        let fadeOut  = SKAction.fadeOut(withDuration: 0.25)
        
        let seq = SKAction.sequence([
            SKAction.group([moveDown, fadeIn]),
            fadeOut,
            .removeFromParent(),
            .run { [weak self] in
                self?.onFinished?()
            }
        ])
        
        arrow.run(seq)
    }
    
    private func runDevastationEffect() {
        // crack.png テクスチャ
        let texture = SKTexture(imageNamed: "crack")
        
        let node = SKSpriteNode(texture: texture)
        // タイルに合わせて「正方形」で配置（SpriteView 側でサイズ指定済み）
        let side = min(size.width, size.height)
        node.size = CGSize(width: side, height: side)
        node.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.zPosition = 10
        node.alpha = 0.0
        addChild(node)
        
        // 0.1 秒でフェードイン → 0.8 秒そのまま → 0.1 秒でフェードアウト
        let fadeIn  = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let stay    = SKAction.wait(forDuration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        
        let seq = SKAction.sequence([
            fadeIn,
            stay,
            fadeOut,
            .removeFromParent(),
            .run { [weak self] in
                self?.onFinished?()
            }
        ])
        
        node.run(seq)
    }
}

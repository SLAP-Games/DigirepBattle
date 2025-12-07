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
        case place
        case harvest
        case tileSnow
        case tileDesert
        case tileVolcano
        case tileJungle
        case tilePlain
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
        case .place: runPlaceEffect()
        case .harvest: runHarvestEffect()
        case .tileSnow:
            runTileChangeEffect(primary: UIColor.white, accent: UIColor.systemBlue)
        case .tileDesert:
            runTileChangeEffect(primary: UIColor.yellow, accent: UIColor.orange)
        case .tileVolcano:
            runTileChangeEffect(primary: UIColor.orange, accent: UIColor.red)
        case .tileJungle:
            runTileChangeEffect(primary: UIColor.systemTeal, accent: UIColor.blue)
        case .tilePlain:
            runTileChangeEffect(primary: UIColor.systemGreen, accent: UIColor.yellow)
        }
    }
    
    // MARK: - 各エフェクト
    
    private func runPlaceEffect() {
        let unit = min(size.width, size.height)

        // ====================================
        // 1) cyan の楕円：拡大しながらフェードアウト
        // ====================================
        let baseWidth: CGFloat = min(size.width * 0.9, 120)
        let baseHeight: CGFloat = min(unit * 0.3, 24)

        let ellipse = SKShapeNode(ellipseOf: CGSize(width: baseWidth, height: baseHeight))
        ellipse.position = CGPoint(x: size.width / 2, y: unit * 0.20)
        ellipse.fillColor = UIColor.cyan.withAlphaComponent(0.25)
        ellipse.strokeColor = UIColor.cyan.withAlphaComponent(0.8)
        ellipse.glowWidth = 4.0
        ellipse.lineWidth = 1.5
        ellipse.alpha = 0.0
        ellipse.zPosition = 8
        addChild(ellipse)

        let ellipseAnim = SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.10),
                SKAction.scale(to: 0.9, duration: 0.10)
            ]),
            SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.55),
                SKAction.fadeOut(withDuration: 0.55)
            ]),
            .removeFromParent()
        ])
        ellipse.setScale(0.7)
        ellipse.run(ellipseAnim)

        // ====================================
        // 2) cyan パーティクル：上方向に湧き出て消える
        // ====================================
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "effectStar") // 既存テクスチャを流用
        emitter.position = ellipse.position
        emitter.particlePositionRange = CGVector(dx: baseWidth * 0.45, dy: unit * 0.05)

        emitter.particleBirthRate = 35
        emitter.particleLifetime = 0.9
        emitter.particleLifetimeRange = 0.3

        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 12

        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 40

        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.8

        let scaleFactor = min(size.width, 120) / 120.0
        emitter.particleScale = 0.18 * scaleFactor
        emitter.particleScaleRange = 0.06 * scaleFactor
        emitter.particleScaleSpeed = -0.12 * scaleFactor

        emitter.zPosition = 8
        addChild(emitter)

        let seq = SKAction.sequence([
            .wait(forDuration: 0.7),
            .run { emitter.particleBirthRate = 0 },
            .wait(forDuration: 0.8),
            .removeFromParent(),
            .run { [weak self] in self?.onFinished?() }
        ])
        emitter.run(seq)

        // 効果音
        onPlaySound?(.place)
    }

    private func runTileChangeEffect(primary: UIColor, accent: UIColor) {
        let minSide = min(size.width, size.height)
        let rectSize = CGSize(width: minSide * 0.9, height: minSide * 0.9)
        let overlay = SKShapeNode(rectOf: rectSize, cornerRadius: minSide * 0.18)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = primary.withAlphaComponent(0.35)
        overlay.strokeColor = accent.withAlphaComponent(0.9)
        overlay.lineWidth = 4
        overlay.alpha = 0
        overlay.setScale(0.7)
        overlay.zPosition = 5
        addChild(overlay)

        let overlayAnim = SKAction.sequence([
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.12),
                SKAction.scale(to: 1.0, duration: 0.12)
            ]),
            SKAction.wait(forDuration: 0.3),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.scale(to: 1.2, duration: 0.35)
            ]),
            .removeFromParent()
        ])
        overlay.run(overlayAnim)

        let ring = SKShapeNode(circleOfRadius: minSide * 0.45)
        ring.position = overlay.position
        ring.strokeColor = accent.withAlphaComponent(0.8)
        ring.lineWidth = 3
        ring.alpha = 0
        ring.zPosition = 6
        addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.08),
                SKAction.scale(to: 1.05, duration: 0.08)
            ]),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 1.3, duration: 0.4)
            ]),
            .removeFromParent()
        ]))

        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "effectStar")
        emitter.position = overlay.position
        emitter.particleBirthRate = 45
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.particlePositionRange = CGVector(dx: rectSize.width * 0.4, dy: rectSize.height * 0.4)
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 30
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.5
        emitter.particleScale = 0.16
        emitter.particleScaleRange = 0.06
        emitter.particleScaleSpeed = -0.18
        emitter.particleColor = accent
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 7
        addChild(emitter)

        let seq = SKAction.sequence([
            .wait(forDuration: 0.25),
            .run { emitter.particleBirthRate = 0 },
            .wait(forDuration: 0.4),
            .removeFromParent()
        ])
        emitter.run(seq)
    }
    
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
        emitter.particleBirthRate = 35
        emitter.particleLifetime = 1.2
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
        
        emitter.particleBirthRate = 35
        emitter.particleLifetime = 1.1
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
    
    private func runHarvestEffect() {
        let unit = min(size.width, size.height)
        
        // 足元の高さ（タイルの下辺あたり）
        let groundY = unit * 0.18
        
        // 草1本のサイズ
        let bladeWidth  = unit * 0.06
        let bladeHeight = unit * 0.42
        
        let bladeCount = 15   // 生やす草の本数
        
        for i in 0..<bladeCount {
            // 画面中央を基準に横方向に並べる
            let offset = (CGFloat(i) - CGFloat(bladeCount - 1) / 2.0) * bladeWidth * 0.8
            let x = size.width / 2 + offset
            
            // 草1本（丸みのある長方形）
            let path = CGMutablePath()
            let rect = CGRect(
                x: -bladeWidth / 2,
                y: 0,
                width: bladeWidth,
                height: bladeHeight
            )
            path.addRoundedRect(in: rect,
                                cornerWidth: bladeWidth / 2,
                                cornerHeight: bladeWidth / 2)
            
            let blade = SKShapeNode(path: path)
            blade.fillColor   = UIColor.systemGreen
            blade.strokeColor = UIColor.black.withAlphaComponent(0.2)
            blade.lineWidth   = 1.0
            blade.glowWidth   = 4.0
            blade.zPosition   = 9
            blade.position    = CGPoint(x: x, y: groundY)
            
            // 最初は地面から生えていない状態（縦スケール0 & 透明）
            blade.yScale = 0.0
            blade.alpha  = 0.0
            
            addChild(blade)
            
            // 少しずつ時間差で生やす
            let delay = 0.04 * Double(i)
            
            let grow = SKAction.sequence([
                .wait(forDuration: delay),
                SKAction.group([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.12),
                    SKAction.scaleY(to: 1.0, duration: 0.18)   // ニョキッと伸びる
                ]),
                .wait(forDuration: 0.25),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: unit * 0.05, duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25)
                ]),
                .removeFromParent()
            ])
            
            blade.run(grow)
        }
        
        // 全体の終了タイミングで onFinished を呼ぶ
        let totalDuration = 0.04 * Double(bladeCount) + 0.18 + 0.25 + 0.25
        let seq = SKAction.sequence([
            .wait(forDuration: totalDuration),
            .run { [weak self] in
                self?.onFinished?()
            }
        ])
        run(seq)
    }

}

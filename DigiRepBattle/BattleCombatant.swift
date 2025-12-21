//
//  BattleCombatant.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI
import SpriteKit
import Combine

// MARK: - Models
public struct BattleCombatant: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let imageName: String
    public var hp: Int
    public let hpMax: Int
    public let power: Int
    public let durability: Int
    public var itemPower: Int
    public var itemDurability: Int
    public let resist: Int
    public let skills: [CreatureSkill]
    public let gatherAttackBonus: Int
    public let gatherDefenseBonus: Int

    public func attackSkillBonus(for attr: BattleAttribute) -> Int {
        skills.totalBattleAttackBonus(for: attr)
    }
    public func defenseSkillBonus(for attr: BattleAttribute) -> Int {
        skills.totalBattleDefenseBonus(for: attr)
    }

    public init(
        name: String,
        imageName: String,
        hp: Int, hpMax: Int,
        power: Int, durability: Int,
        itemPower: Int, itemDurability: Int,
        resist: Int,
        skills: [CreatureSkill] = [],
        gatherAttackBonus: Int = 0,
        gatherDefenseBonus: Int = 0
    ) {
        self.name = name
        self.imageName = imageName
        self.hp = hp
        self.hpMax = hpMax
        self.power = power
        self.durability = durability
        self.itemPower = itemPower
        self.itemDurability = itemDurability
        self.resist = resist
        self.skills = skills.cappedForBattle
        self.gatherAttackBonus = gatherAttackBonus
        self.gatherDefenseBonus = gatherDefenseBonus
    }
}

public enum BattleAttribute: String { case normal, dry, water, heat, cold }

// MARK: - Helpers
fileprivate func resistColor(for attr: BattleAttribute) -> Color {
    switch attr {
    case .heat:  return .red
    case .water: return .blue
    case .dry:   return Color(red: 0.85, green: 0.76, blue: 0.62) // beige
    case .cold:  return .cyan
    case .normal: return .gray
    }
}

fileprivate enum AttackDirection {
    case leftToRight
    case rightToLeft
}

fileprivate struct SpeedLineField: View {
    let direction: AttackDirection
    @State private var animatePhase = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let travel = width * 1.2
            let startX = direction == .leftToRight ? -travel : travel
            let endX = -startX

            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                ForEach(0..<8, id: \.self) { idx in
                    let spacing = height / 8
                    Capsule()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: max(width * 0.45, 150), height: 2)
                        .offset(
                            x: animatePhase ? endX : startX,
                            y: -height / 2 + spacing * CGFloat(idx) + spacing * 0.3
                        )
                        .animation(
                            .linear(duration: 0.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(idx) * 0.06),
                            value: animatePhase
                        )
                }
            }
            .clipped()
            .onAppear { animatePhase = true }
            .onDisappear { animatePhase = false }
        }
    }
}

fileprivate final class BloodParticleScene: SKScene {
    private let splashColor: UIColor

    init(size: CGSize, splashColor: Color) {
        self.splashColor = UIColor(splashColor)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        runSplash()
    }

    private func runSplash() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for idx in 0..<26 {
            let radius = CGFloat.random(in: size.width * 0.25...size.width * 0.55)
            let angle = (CGFloat(idx) / 26.0) * .pi * 2 + CGFloat.random(in: -0.3...0.3)
            let target = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )

            let node = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            node.fillColor = splashColor
            node.strokeColor = splashColor.withAlphaComponent(0.4)
            node.lineWidth = 0.3
            node.position = center
            node.alpha = 0.95
            addChild(node)

            let travel = SKAction.move(to: target, duration: 0.45)
            travel.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.45)
            let scale = SKAction.scale(to: 0.2, duration: 0.45)
            let group = SKAction.group([travel, fade, scale])
            let delay = SKAction.wait(forDuration: Double.random(in: 0.0...0.08))
            node.run(SKAction.sequence([delay, group, .removeFromParent()]))
        }

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.removeAllChildren() }
        ])
        run(cleanup)
    }
}

fileprivate struct BloodParticleSplash: View {
    let color: Color
    private var scene: SKScene {
        BloodParticleScene(size: CGSize(width: 90, height: 90), splashColor: color)
    }

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .allowsHitTesting(false)
    }
}

// MARK: - Segmented bars
fileprivate struct SegmentedBar: View {
    struct Segment: Identifiable { let id = UUID(); let value: CGFloat; let color: Color }
    let maxValue: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let segments: [Segment]

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.6))
                HStack(spacing: 0) {
                    ForEach(segments) { seg in
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(seg.color)
                            .frame(width: max(0, min(W, W * (seg.value / maxValue))), height: height)
                    }
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Stat rows
fileprivate struct StatRow: View {
    let title: String
    let displayedValue: Text
    let bar: SegmentedBar

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.bestTenCaption)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(displayedValue)")
                    .font(.bestTenCaption2)
                    .foregroundStyle(.white)
            }
            bar
                .frame(height: 10)
        }
    }
}

// MARK: - One side HUD
fileprivate struct FighterHUD: View {
    let who: BattleCombatant
    let attr: BattleAttribute
    @Binding var animatedHP: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(who.name)
                .font(.bestTenFootnote)
                .foregroundStyle(.white.opacity(0.9))

            // HP (max = hpMax, green)
            StatRow(
                title: "HP",
                displayedValue: Text("\(Int(animatedHP))"),
                bar: SegmentedBar(
                    maxValue: CGFloat(who.hpMax),
                    height: 10, cornerRadius: 6,
                    segments: [
                        .init(value: max(0, animatedHP), color: .green),
                        .init(value: CGFloat(max(0, who.hpMax) - Int(animatedHP)), color: .clear)
                    ]
                )
            )

            // ATK (max 150): white=power*2, resistColor=resist*4, purple=itemPower, rest black
            let atkWhite = CGFloat(who.power * 2)
            let atkRes   = CGFloat(who.resist * 4)
            let atkItem  = CGFloat(who.itemPower)
            let atkSkill = CGFloat(who.attackSkillBonus(for: attr) + who.gatherAttackBonus)
            let atkSum   = min(150, atkWhite + atkRes + atkItem + atkSkill)
            StatRow(
                title: "戦闘力",
                displayedValue: Text("\(Int(atkWhite)) + \(Int(atkRes)) + \(Int(atkItem)) + \(Int(atkSkill))"),
                bar: SegmentedBar(
                    maxValue: 150, height: 10, cornerRadius: 6,
                    segments: [
                        .init(value: atkWhite, color: .white),
                        .init(value: atkRes, color: resistColor(for: attr)),
                        .init(value: atkItem, color: .purple),
                        .init(value: atkSkill, color: .red),
                        .init(value: max(0, 150 - atkSum), color: .black)
                    ]
                )
            )

            // DEF (max 100): white=durability, resistColor=resist, purple=itemDurability, rest black
            let defWhite = CGFloat(who.durability)
            let defRes   = CGFloat(who.resist)
            let defItem  = CGFloat(who.itemDurability)
            let defSkill = CGFloat(who.defenseSkillBonus(for: attr) + who.gatherDefenseBonus)
            let defSum   = min(100, defWhite + defRes + defItem + defSkill)
            StatRow(
                title: "耐久力",
                displayedValue: Text("\(Int(defWhite)) + \(Int(defRes)) + \(Int(defItem)) + \(Int(defSkill))"),
                bar: SegmentedBar(
                    maxValue: 100, height: 10, cornerRadius: 6,
                    segments: [
                        .init(value: defWhite, color: .white),
                        .init(value: defRes, color: resistColor(for: attr)),
                        .init(value: defItem, color: .purple),
                        .init(value: defSkill, color: .red),
                        .init(value: max(0, 100 - defSum), color: .black)
                    ]
                )
            )
        }
    }
}

// MARK: - Battle Overlay
public struct BattleOverlayView: View {
    public let left: BattleCombatant
    public let right: BattleCombatant
    public let attribute: BattleAttribute
    public let onFinished: (BattleCombatant, BattleCombatant) -> Void
    let defenderHasFirstStrike: Bool
    
    @Binding public var isItemSelecting: Bool
    public let isShowingBattleSpellEffect: Bool
    public let battleSpellEffectID: UUID

//    @StateObject private var vm = GameVM()
    
    @State private var leftOffset: CGFloat = 0
    @State private var rightOffset: CGFloat = 0
    @State private var leftHPAnim: CGFloat
    @State private var rightHPAnim: CGFloat
    @State private var L: BattleCombatant
    @State private var R: BattleCombatant
    @State private var showDmgLeft = false
    @State private var showDmgRight = false
    @State private var dmgLeft: Int = 0
    @State private var dmgRight: Int = 0
    @State private var isFinished = false
    @State private var useFirstImage = true
    @State private var hasStartedTimeline = false
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()
    @State private var flashOpacity: Double = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var showLeftBattleBackground = false
    @State private var showRightBattleBackground = false
    @State private var leftBattleBGOffset: CGFloat = -400
    @State private var rightBattleBGOffset: CGFloat = 400
    @State private var leftBattleBGOpacity: Double = 0
    @State private var rightBattleBGOpacity: Double = 0
    @State private var currentEnergyDirection: AttackDirection?
    @State private var containerWidth: CGFloat = 0
    @State private var skipIntroDelay = false
    @State private var currentCriticalAttack = false
    @State private var currentCriticalAttackerIsLeft = true
    @State private var criticalFlashOpacity: Double = 0

    public init(
        left: BattleCombatant,
        right: BattleCombatant,
        attribute: BattleAttribute,
        defenderHasFirstStrike: Bool,
        isItemSelecting: Binding<Bool>,
        isShowingBattleSpellEffect: Bool,
        battleSpellEffectID: UUID,
        onFinished: @escaping (BattleCombatant, BattleCombatant) -> Void
    ) {
        self.left = left
        self.right = right
        self.attribute = attribute
        self.defenderHasFirstStrike = defenderHasFirstStrike
        self._isItemSelecting = isItemSelecting
        self.isShowingBattleSpellEffect = isShowingBattleSpellEffect
        self.battleSpellEffectID = battleSpellEffectID
        self.onFinished = onFinished
        _L = State(initialValue: left)
        _R = State(initialValue: right)
        _leftHPAnim = State(initialValue: CGFloat(left.hp))
        _rightHPAnim = State(initialValue: CGFloat(right.hp))
    }

    public var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let bandH: CGFloat = min(H * 0.06, 50)
            let centerH: CGFloat = min(H * 0.22, 130)
            let hudH: CGFloat = 76
            let totalH: CGFloat = bandH * 2 + centerH + hudH
            
            let mainBattleLayers = ZStack {
                ZStack {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .onAppear { containerWidth = W }
                        .onChange(of: geo.size.width) { _, newWidth in
                            containerWidth = newWidth
                        }
                    Color.black.opacity(0.6)
                    
                    VStack(spacing: 0) {
                        // 上スライド帯
                        InfiniteSlidingStrip(imageName: "bandTop", containerWidth: W, height: bandH, direction: .left, opacity: 0.35)
                        
                        // センター：キャラ画像＋ダメージのみ
                        ZStack {
                            Image("battleBackground")
                                .resizable(resizingMode: .stretch)
                                .frame(width: W)
                                .frame(height: centerH)
                            
                            if let direction = currentEnergyDirection {
                                SpeedLineField(direction: direction)
                                    .transition(.opacity)
                                    .frame(width: W, height: centerH)
                                    .allowsHitTesting(false)
                            }

                            HStack {
                                Spacer(minLength: 0)
                                ZStack {
                                    fighterSpriteView(isLeft: true, who: L)
                                        .frame(width: W * 0.38)
                                        .offset(x: leftOffset)
                                        .zIndex(0)
                                    if showLeftBattleBackground {
                                        fighterBackgroundView(isAttacker: true, who: L)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .opacity(leftBattleBGOpacity)
                                            .offset(x: leftBattleBGOffset)
                                            .zIndex(1)
                                    }
                                    if showDmgLeft {
                                        BloodParticleSplash(color: .red)
                                            .frame(width: 140, height: 140)
                                            .offset(y: -10)
                                            .zIndex(2)
                                    }
                                }
                                .frame(width: W * 0.48, height: centerH)
                                Spacer()
                                ZStack {
                                    fighterSpriteView(isLeft: false, who: R)
                                        .frame(width: W * 0.38)
                                        .offset(x: rightOffset)
                                        .zIndex(0)
                                    if showRightBattleBackground {
                                        fighterBackgroundView(isAttacker: false, who: R)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .opacity(rightBattleBGOpacity)
                                            .offset(x: rightBattleBGOffset)
                                            .zIndex(1)
                                    }
                                    if showDmgRight {
                                        BloodParticleSplash(color: .red)
                                            .frame(width: 140, height: 140)
                                            .offset(y: -10)
                                            .zIndex(2)
                                    }
                                }
                                .frame(width: W * 0.48, height: centerH)
                                Spacer(minLength: 0)
                            }
                            .frame(height: centerH)
                            .onReceive(timer) { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    useFirstImage.toggle()
                                }
                            }
                            
                            // ダメージ表示
                            if showDmgLeft {
                                Text("-\(dmgLeft)")
                                    .font(.bestTen(size: 28))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                                    .shadow(radius: 6)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .position(x: W * 0.18, y: centerH * 0.25)
                            }
                            if showDmgRight {
                                Text("-\(dmgRight)")
                                    .font(.bestTen(size: 28))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                                    .shadow(radius: 6)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .position(x: W * 0.82, y: centerH * 0.25)
                            }
                        }
                        
                        // 下スライド帯
                        InfiniteSlidingStrip(imageName: "bandBottom", containerWidth: W, height: bandH, direction: .right, opacity: 0.35)
                        
                        // ★帯の「下」に HUD を配置★
                        hudRow()
                            .frame(height: hudH)
                    }
                    .frame(maxWidth: .infinity, maxHeight: totalH) // HUD分も含めて確保
                }
                .onAppear {
                    setupInitialOffsets(W: W)
                    if !isItemSelecting {
                        startTimelineIfNeeded(W: W)
                    }
                }
                .onChange(of: isItemSelecting) { oldValue, newValue in
                    if oldValue == true && newValue == false {
                        skipIntroDelay = true
                        startTimelineIfNeeded(W: W)
                    }
                }
                
                if isItemSelecting {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)

                    VStack(spacing: 16) {
                        Text("手札から装備選択")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Button {
                            isItemSelecting = false
                        } label: {
                            Text("使用しない")
                                .font(.bestTenHeadline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .padding()
                }
            }
            mainBattleLayers
                .offset(y: shakeOffset)
                .overlay(
                    Color.red
                        .opacity(flashOpacity)
                        .blendMode(.screen)
                        .ignoresSafeArea()
                )
                .overlay(
                    Color.white
                        .opacity(criticalFlashOpacity)
                        .blendMode(.screen)
                        .ignoresSafeArea()
                )
                .overlay(
                    Color.white
                        .opacity(isShowingBattleSpellEffect ? 0.45 : 0)
                        .blendMode(.screen)
                        .ignoresSafeArea()
                )
                .overlay {
                    if isShowingBattleSpellEffect {
                        BattleSpellCastView(token: battleSpellEffectID)
                            .frame(width: geo.size.width * 0.45)
                            .transition(.opacity)
                    }
                }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .transition(.opacity)
        .onChange(of: left) { oldValue, newValue in
            L = newValue
        }
        .onChange(of: right) { oldValue, newValue in
            R = newValue
        }
    }

    @ViewBuilder
    private func fighterSpriteView(isLeft: Bool, who: BattleCombatant) -> some View {
        Image(useFirstImage ? "\(who.imageName)1" : "\(who.imageName)2")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 70)
            .scaleEffect(x: isLeft ? 1 : -1, y: 1)
            .shadow(color: .white.opacity(0.15), radius: 8, x: 0, y: 3)
    }

    private func fighterBackgroundView(isAttacker: Bool, who: BattleCombatant) -> some View {
        let bgName = "\(who.imageName)Battle"
        return Image(bgName)
            .resizable()
            .scaledToFit()
            .scaleEffect(x: isAttacker ? 1 : -1, y: 1)
            .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 8)
    }

    
    @ViewBuilder
    private func hudRow() -> some View {
        HStack(alignment: .top, spacing: 12) {
            // 左側HUD（左寄せ）
            VStack(alignment: .leading, spacing: 0) {
                FighterHUD(who: L, attr: attribute, animatedHP: $leftHPAnim)
            }
            Spacer(minLength: 0)
            // 右側HUD（右寄せ）
            VStack(alignment: .trailing, spacing: 0) {
                FighterHUD(who: R, attr: attribute, animatedHP: $rightHPAnim)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Flow
    private func setupInitialOffsets(W: CGFloat) {
        leftOffset = 0      // left on-screen
        rightOffset = W     // right off-screen to the right
    }
    
    private func startTimelineIfNeeded(W: CGFloat) {
        guard !hasStartedTimeline else { return }
        hasStartedTimeline = true
        setupInitialOffsets(W: W)
        timeline()
    }

    private func timeline() {
        let delay: Double = skipIntroDelay ? 0.0 : 3.0
        skipIntroDelay = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            guard !isFinished else { return }

            if defenderHasFirstStrike {
                // ★ 先制あり
                runFirstStrikeTimeline()
            } else {
                // ★ 通常
                runNormalTimeline()
            }
        }
    }
    
    private func runNormalTimeline() {
        performAttackSequence(attackerIsLeft: true) { [self] in
            guard !isFinished else { return }
            performAttackSequence(attackerIsLeft: false) { [self] in
                guard !isFinished else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                    guard !isFinished else { return }
                    onFinished(L, R)
                }
            }
        }
    }

    private func runFirstStrikeTimeline() {
        performAttackSequence(attackerIsLeft: false) { [self] in
            guard !isFinished else { return }
            performAttackSequence(attackerIsLeft: true) { [self] in
                guard !isFinished else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                    guard !isFinished else { return }
                    onFinished(L, R)
                }
            }
        }
    }

    private func performAttackSequence(attackerIsLeft: Bool, completion: @escaping () -> Void) {
        guard !isFinished else { return }
        rollCriticalChance(forLeftAttacker: attackerIsLeft)
        startBattleEffect(attackerIsLeft: attackerIsLeft) { [self] in
            guard !isFinished else { return }
            focusOnDefender(attackerIsLeft: attackerIsLeft) {
                guard !isFinished else { return }
                completion()
            }
        }
    }

    private func rollCriticalChance(forLeftAttacker: Bool) {
        currentCriticalAttackerIsLeft = forLeftAttacker
        let attacker = forLeftAttacker ? L : R
        let chance = attacker.skills.contains(.criticalSkill) ? 30 : 10
        currentCriticalAttack = Int.random(in: 0..<100) < chance
    }

    private func isCriticalHit(attackerIsLeft: Bool) -> Bool {
        currentCriticalAttack && currentCriticalAttackerIsLeft == attackerIsLeft
    }

    private func triggerCriticalCueIfNeeded(forLeft isLeft: Bool) {
        guard isCriticalHit(attackerIsLeft: isLeft) else { return }
        SoundManager.shared.playCriticalSound()
        criticalFlashOpacity = 0.9
        withAnimation(.easeOut(duration: 0.45)) {
            criticalFlashOpacity = 0
        }
    }

    private func startBattleEffect(attackerIsLeft: Bool, completion: @escaping () -> Void) {
        guard !isFinished else { return }
        let direction: AttackDirection = attackerIsLeft ? .leftToRight : .rightToLeft
        let slideDuration: Double = 1.5
        withAnimation(.easeInOut(duration: 0.2)) {
            currentEnergyDirection = direction
        }
        triggerBackground(forLeft: attackerIsLeft, duration: slideDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration) { [self] in
            guard !isFinished else { return }
            hideBackground(forLeft: attackerIsLeft) {
                withAnimation(.easeOut(duration: 0.2)) {
                    currentEnergyDirection = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion()
                }
            }
        }
    }

    private func triggerBackground(forLeft isLeft: Bool, duration: Double) {
        let travel = max(containerWidth, 400)
        if isLeft {
            leftBattleBGOffset = -travel
            leftBattleBGOpacity = 0
            showLeftBattleBackground = true
            withAnimation(.easeOut(duration: duration)) {
                leftBattleBGOffset = 0
                leftBattleBGOpacity = 1
            }
            triggerCriticalCueIfNeeded(forLeft: true)
        } else {
            rightBattleBGOffset = travel
            rightBattleBGOpacity = 0
            showRightBattleBackground = true
            withAnimation(.easeOut(duration: duration)) {
                rightBattleBGOffset = 0
                rightBattleBGOpacity = 1
            }
            triggerCriticalCueIfNeeded(forLeft: false)
        }
    }

    private func hideBackground(forLeft isLeft: Bool, completion: @escaping () -> Void) {
        let travel = max(containerWidth, 400)
        let hideDuration = 0.4
        withAnimation(.easeIn(duration: hideDuration)) {
            if isLeft {
                leftBattleBGOffset = travel * 0.2
                leftBattleBGOpacity = 0
            } else {
                rightBattleBGOffset = -travel * 0.2
                rightBattleBGOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDuration) { [self] in
            if isLeft {
                showLeftBattleBackground = false
                leftBattleBGOffset = -travel
            } else {
                showRightBattleBackground = false
                rightBattleBGOffset = travel
            }
            completion()
        }
    }

    private func focusOnDefender(attackerIsLeft: Bool, completion: @escaping () -> Void) {
        let slideDuration: Double = 0.6
        withAnimation(.easeInOut(duration: slideDuration)) {
            if attackerIsLeft {
                leftOffset = -600
                rightOffset = 0
            } else {
                leftOffset = 0
                rightOffset = 600
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration + 0.05) { [self] in
            guard !isFinished else { return }
            resolveAttack(attackerIsLeft: attackerIsLeft)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                completion()
            }
        }
    }

    // MARK: - Damage + HP animation
    private func resolveAttack(attackerIsLeft: Bool) {
        func atkValue(of c: BattleCombatant) -> Int {
            c.power * 2 + c.resist * 4 + c.itemPower + c.attackSkillBonus(for: attribute) + c.gatherAttackBonus
        }
        func defValue(of c: BattleCombatant) -> Int {
            c.durability + c.resist + c.itemDurability + c.defenseSkillBonus(for: attribute) + c.gatherDefenseBonus
        }

        guard !isFinished else { return }

        if attackerIsLeft {
            let isCritical = isCriticalHit(attackerIsLeft: true)
            var atk = atkValue(of: L)
            if isCritical {
                let boosted = Int((Double(atk) * 1.5).rounded())
                atk = max(atk + 1, boosted)
            }
            let def = defValue(of: R)
            let dmg = max(0, atk - def)
            dmgRight = dmg
            showHit(onRight: true, isCritical: isCritical)
            R.hp = max(0, R.hp - dmg)
            withAnimation(.easeOut(duration: 0.6)) { rightHPAnim = CGFloat(R.hp) }

            if R.hp <= 0 { finishNow() }
        } else {
            let isCritical = isCriticalHit(attackerIsLeft: false)
            var atk = atkValue(of: R)
            if isCritical {
                let boosted = Int((Double(atk) * 1.5).rounded())
                atk = max(atk + 1, boosted)
            }
            let def = defValue(of: L)
            let dmg = max(0, atk - def)
            dmgLeft = dmg
            showHit(onRight: false, isCritical: isCritical)
            L.hp = max(0, L.hp - dmg)
            withAnimation(.easeOut(duration: 0.6)) { leftHPAnim = CGFloat(L.hp) }

            if L.hp <= 0 { finishNow() }
        }
        currentCriticalAttack = false
    }

    private func showHit(onRight: Bool, isCritical: Bool) {
        if isCritical {
            SoundManager.shared.playAttackSound2()
        } else {
            SoundManager.shared.playAttackSound()
        }
        triggerImpactEffect()
        if onRight {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showDmgRight = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.2)) { showDmgRight = false }
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showDmgLeft = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.2)) { showDmgLeft = false }
            }
        }
    }

    private func triggerImpactEffect() {
        flashOpacity = 0.4
        withAnimation(.easeOut(duration: 0.25)) {
            flashOpacity = 0
        }

        let shakeSequence: [CGFloat] = [-12, 10, -8, 6, -3, 0]
        for (idx, value) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = value
                }
            }
        }
    }
    
    private func finishNow() {
        guard !isFinished else { return }
        isFinished = true
        // ダメージ数値やHPバーアニメが見えるように僅かに待ってから終了
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onFinished(L, R)
        }
//        vm.expectBattleCardSelection = false
    }
}

private struct BattleSpellCastView: View {
    let token: UUID
    @State private var isAnimating = false

    var body: some View {
        Image("cardLreverse")
            .resizable()
            .scaledToFit()
            .shadow(color: .yellow.opacity(0.4), radius: 25, y: 10)
            .opacity(isAnimating ? 0.0 : 0.95)
            .scaleEffect(isAnimating ? 0.35 : 1.2)
            .blendMode(.screen)
            .onAppear { startAnimation() }
            .onChange(of: token) { _, _ in startAnimation() }
    }

    private func startAnimation() {
        withAnimation(.none) {
            isAnimating = false
        }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

//
//  BattleCombatant.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI
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

    public init(
        name: String,
        imageName: String,
        hp: Int, hpMax: Int,
        power: Int, durability: Int,
        itemPower: Int, itemDurability: Int,
        resist: Int
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
                    .font(.caption)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(displayedValue)")
                    .font(.caption2)
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
            Text(who.name).font(.footnote).foregroundStyle(.white.opacity(0.9))

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
            let atkSum   = min(150, atkWhite + atkRes + atkItem)
            StatRow(
                title: "戦闘力",
                displayedValue: Text("\(Int(atkWhite)) + \(Int(atkRes)) + \(Int(atkItem))"),
                bar: SegmentedBar(
                    maxValue: 150, height: 10, cornerRadius: 6,
                    segments: [
                        .init(value: atkWhite, color: .white),
                        .init(value: atkRes, color: resistColor(for: attr)),
                        .init(value: atkItem, color: .purple),
                        .init(value: max(0, 150 - atkSum), color: .black)
                    ]
                )
            )

            // DEF (max 100): white=durability, resistColor=resist, purple=itemDurability, rest black
            let defWhite = CGFloat(who.durability)
            let defRes   = CGFloat(who.resist)
            let defItem  = CGFloat(who.itemDurability)
            let defSum   = min(100, defWhite + defRes + defItem)
            StatRow(
                title: "耐久力",
                displayedValue: Text("\(Int(defWhite)) + \(Int(defRes)) + \(Int(defItem))"),
                bar: SegmentedBar(
                    maxValue: 100, height: 10, cornerRadius: 6,
                    segments: [
                        .init(value: defWhite, color: .white),
                        .init(value: defRes, color: resistColor(for: attr)),
                        .init(value: defItem, color: .purple),
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
    
    @Binding public var isItemSelecting: Bool

    @StateObject private var vm = GameVM()
    
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

    public init(
        left: BattleCombatant,
        right: BattleCombatant,
        attribute: BattleAttribute,
        isItemSelecting: Binding<Bool>,
        onFinished: @escaping (BattleCombatant, BattleCombatant) -> Void
    ) {
        self.left = left
        self.right = right
        self.attribute = attribute
        self._isItemSelecting = isItemSelecting
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
            
            ZStack {
                ZStack {
                    Color.black.opacity(0.6)
                    
                    VStack(spacing: 0) {
                        // 上スライド帯
                        InfiniteSlidingStrip(imageName: "bandTop", containerWidth: W, height: bandH, direction: .left, opacity: 0.35)
                        
                        // センター：キャラ画像＋ダメージのみ
                        ZStack {
                            Rectangle().fill(Color.black).frame(height: centerH)
                            
                            HStack {
                                Spacer(minLength: 0)
                                // 画像のみ（HUDは出さない）
                                fighterSpriteView(isLeft: true, who: L)
                                    .frame(width: W * 0.38)
                                    .offset(x: leftOffset)
                                Spacer()
                                fighterSpriteView(isLeft: false, who: R)
                                    .frame(width: W * 0.38)
                                    .offset(x: rightOffset)
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
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.red)
                                    .shadow(radius: 6)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                    .position(x: W * 0.18, y: centerH * 0.25)
                            }
                            if showDmgRight {
                                Text("-\(dmgRight)")
                                    .font(.system(size: 28, weight: .bold))
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
                        startTimelineIfNeeded(W: W)
                    }
                }
                
                if isItemSelecting {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)

                    VStack(spacing: 16) {
                        Text("装備品を手札から選択してください")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Button {
                            isItemSelecting = false
                        } label: {
                            Text("使用しない")
                                .font(.headline)
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
        // 0s: intro (left on, right off)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            guard !isFinished else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                leftOffset = -600
                rightOffset = 0
            }
            // resolve attack 1 (left -> right) after slide
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [self] in
                guard !isFinished else { return }
                resolveAttack(attackerIsLeft: true)
                
                // 3s later: reverse slide
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                    guard !isFinished else { return }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        leftOffset = 0
                        rightOffset = 600
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [self] in
                        guard !isFinished else { return }
                        resolveAttack(attackerIsLeft: false)
                        
                        // 3s after left settles, finish（生存していたら通常終了）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
                            guard !isFinished else { return }
                            onFinished(L, R)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Damage + HP animation
    private func resolveAttack(attackerIsLeft: Bool) {
        func atkValue(of c: BattleCombatant) -> Int { c.power * 2 + c.resist * 4 + c.itemPower }
        func defValue(of c: BattleCombatant) -> Int { c.durability + c.resist + c.itemDurability }

        guard !isFinished else { return }

        if attackerIsLeft {
            let atk = atkValue(of: L)
            let def = defValue(of: R)
            let dmg = max(0, atk - def)
            dmgRight = dmg
            showHit(onRight: true)
            R.hp = max(0, R.hp - dmg)
            withAnimation(.easeOut(duration: 0.6)) { rightHPAnim = CGFloat(R.hp) }

            if R.hp <= 0 { finishNow() }
        } else {
            let atk = atkValue(of: R)
            let def = defValue(of: L)
            let dmg = max(0, atk - def)
            dmgLeft = dmg
            showHit(onRight: false)
            L.hp = max(0, L.hp - dmg)
            withAnimation(.easeOut(duration: 0.6)) { leftHPAnim = CGFloat(L.hp) }

            if L.hp <= 0 { finishNow() }
        }
    }

    private func showHit(onRight: Bool) {
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
    
    private func finishNow() {
        guard !isFinished else { return }
        isFinished = true
        // ダメージ数値やHPバーアニメが見えるように僅かに待ってから終了
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onFinished(L, R)
        }
        vm.expectBattleCardSelection = false
    }
}

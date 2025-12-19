//
//  FlipAngle.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct FlipAngle<Front: View, Back: View>: View, Animatable {
    // ← Animatable 準拠を追加
    var angle: Double
    var perspective: CGFloat = 0.6
    let front: () -> Front
    let back: () -> Back

    // これを追加：angle をアニメーションのドライバにする
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    init(angle: Double,
         perspective: CGFloat = 0.6,
         @ViewBuilder front: @escaping () -> Front,
         @ViewBuilder back: @escaping () -> Back) {
        self.angle = angle
        self.perspective = perspective
        self.front = front
        self.back = back
    }

    var body: some View {
        // 角度正規化（0...360）
        let a = angle.truncatingRemainder(dividingBy: 360)
        let norm = a < 0 ? a + 360 : a
        let showFront = !(90.0...270.0).contains(norm)

        return ZStack {
            front()
                .opacity(showFront ? 1 : 0)
                .zIndex(showFront ? 1 : 0)

            back()
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showFront ? 0 : 1)
                .zIndex(showFront ? 0 : 1)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: perspective)
        // （必要なら）透過ブレンドのチラつき対策
        .drawingGroup() // 任意
    }
}

struct Flip<Front: View, Back: View>: View {
    var isFront: Bool
    @State private var canShowFrontView: Bool
    let duration: Double
    let front: () -> Front
    let back: () -> Back

    init(isFront: Bool,
         duration: Double = 1.0,
         @ViewBuilder front: @escaping () -> Front,
         @ViewBuilder back: @escaping () -> Back) {
        self.isFront = isFront
        self._canShowFrontView = State(initialValue: isFront)
        self.duration = duration
        self.front = front
        self.back = back
    }

    var body: some View {
        ZStack {
            if canShowFrontView {
                front()
            } else {
                back()
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .onChange(of: isFront) { oldValue, newValue in
            // 半分回転したタイミングで front/back を入れ替える
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                self.canShowFrontView = newValue
            }
        }
        .animation(nil, value: canShowFrontView)
        .rotation3DEffect(isFront ? .degrees(0) : .degrees(180),
                          axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: duration), value: isFront)
    }
}

struct FrontCardFace: View {
    let card: Card
    @ObservedObject var vm: GameVM
    let frameImageName: String
    @Binding var isDissolving: Bool
    var onDissolveCompleted: (() -> Void)?
    
    @State private var useFirstImage = true
    @State private var neonProgress: Double = 0.0
    @State private var isRunningDissolve = false
    @State private var didNotifyDissolve = false

    private let neonDuration: Double = 0.85
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    init(card: Card,
         vm: GameVM,
         frameImageName: String,
         isDissolving: Binding<Bool> = .constant(false),
         onDissolveCompleted: (() -> Void)? = nil) {
        self.card = card
        self.vm = vm
        self.frameImageName = frameImageName
        self._isDissolving = isDissolving
        self.onDissolveCompleted = onDissolveCompleted
    }

    var body: some View {
        ZStack {
            cardContent
                .mask(
                    NeonWipeMask(progress: neonProgress, isActive: isRunningDissolve)
                )
                .overlay(
                    NeonLineOverlay(progress: neonProgress)
                        .opacity(isRunningDissolve ? 1 : 0)
                )
        }
        .compositingGroup()
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                useFirstImage.toggle()
            }
        }
        .onAppear {
            if isDissolving {
                startDissolve()
            }
        }
        .onChange(of: isDissolving) { _, newValue in
            if newValue {
                startDissolve()
            } else if !newValue {
                resetDissolveState()
            }
        }
    }

    private var cardContent: some View {
        ZStack {
            Image(frameImageName)
                .resizable()
                .aspectRatio(3/4, contentMode: .fit)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let frameHeight = min(h, w * (4.0 / 3.0))
                let sidePad = w * 0.12
                let topPad  = h * 0.1
                let topSpacing = card.kind == .spell ? topPad * 1.5 : topPad
                let imgH    = h * 0.40
                let heartH  = h * 0.052
                let statsTopGap = h * 0.03
                let detailFontSize = min(w, h) * 0.07

                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacing)

                    ZStack(alignment: .topLeading) {
                        Image(card.imageName(firstVariant: useFirstImage))
                            .resizable()
                            .scaledToFit()

                        if card.kind == .creature {
                            SkillIconRow(
                                skills: card.stats?.cappedSkills ?? [],
                                iconSize: max(24, imgH * 0.22)
                            )
                            .padding(8)
                        }
                    }
                    .frame(height: imgH)
                    .padding(.horizontal, sidePad)

                    if let s = card.stats {
                        HeartRow(count: max(0, min(s.affection, 10)))
                            .frame(height: heartH)
                            .padding(.top, h * 0.07)
                            .padding(.bottom, h * 0.02)
                    } else {
                        Spacer().frame(height: heartH)
                    }

                    VStack(spacing: statsTopGap) {
                        if case .creature = card.kind, let s = card.stats {
                            StatGrid2x4(items: [
                                ("コスト", "\(s.cost)"),
                                ("体力", "\(s.hpMax)"),
                                ("戦闘力", "\(s.power)"),
                                ("耐久力", "\(s.durability)"),
                                ("乾耐性", "\(s.resistDry)"),
                                ("水耐性", "\(s.resistWater)"),
                                ("熱耐性", "\(s.resistHeat)"),
                                ("冷耐性", "\(s.resistCold)")
                            ])
                            .padding(.horizontal, sidePad)
                            .padding(.bottom, h * 0.06)
                        } else {
                            Spacer().frame(height: heartH / 2)
                            VStack(spacing: h * 0.015) {
                                Text("コスト \(spellCostForDisplay())G")
                                    .font(.bestTen(size: detailFontSize))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(vm.spellDescription(for: card))
                                    .font(.bestTen(size: detailFontSize))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                            }
                            .padding(.horizontal, sidePad * 0.7)
                            .padding(.bottom, h * 0.06)
                        }
                    }
                }
                .frame(width: w, height: frameHeight, alignment: .top)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }

    private func spellCostForDisplay() -> Int {
        if let defCost = CardDatabase.definition(for: card.id)?.cost {
            return defCost
        }
        return card.cost
    }

    private func startDissolve() {
        guard !isRunningDissolve else { return }
        isRunningDissolve = true
        didNotifyDissolve = false
        neonProgress = 0.0

        withAnimation(.easeInOut(duration: neonDuration)) {
            neonProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + neonDuration) {
            notifyDissolveCompletion()
        }
    }

    private func resetDissolveState() {
        isRunningDissolve = false
        neonProgress = 0.0
    }

    private func notifyDissolveCompletion() {
        guard !didNotifyDissolve else { return }
        didNotifyDissolve = true
        isRunningDissolve = false
        onDissolveCompleted?()
    }
}

private struct NeonWipeMask: View {
    let progress: Double
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let clamped = isActive ? min(max(progress, 0), 1) : 0
            Color.white
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(
                    x: 1,
                    y: max(0.0001, 1 - clamped),
                    anchor: .bottom
                )
        }
        .allowsHitTesting(false)
    }
}

private struct NeonLineOverlay: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            let height = geo.size.height
            let width = geo.size.width
            let lineThickness = max(4, height * 0.02)
            let glowHeight = lineThickness * 3
            let yTop = (height - lineThickness) * clamped
            let lineCenter = yTop + lineThickness / 2
            let glowCenter = yTop + glowHeight / 2

            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.35),
                        Color.cyan.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width, height: glowHeight)
                .position(x: width / 2, y: glowCenter)

                RoundedRectangle(cornerRadius: lineThickness / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.2),
                                Color.cyan,
                                Color.cyan.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.9, height: lineThickness)
                    .shadow(color: Color.cyan.opacity(0.8), radius: 10, x: 0, y: 0)
                    .position(x: width / 2, y: lineCenter)
            }
            .frame(width: width, height: height)
        }
        .allowsHitTesting(false)
        .compositingGroup()
    }
}

struct BackCardFace: View {
    let frameImageName: String
    // 画像の周囲をカットする量（pt）
    private let trim: CGFloat = 6

    var body: some View {
        ZStack {
            Image(frameImageName)
                .resizable()
                .aspectRatio(3/4, contentMode: .fit)
                // 縁取りをトリミング（上下左右を等幅でカット）
                .mask(
                    Rectangle().inset(by: trim)
                )

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let frameHeight = min(h, w * (4.0 / 3.0))
                let topPad  = h * 0.04
                VStack(spacing: 0) {
                    Spacer().frame(height: topPad)
                    Spacer()
                }
                .frame(width: w, height: frameHeight, alignment: .top)
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - 下パネル：2列×4行のステータス
struct StatGrid2x4: View {
    let items: [(String, String)] // 8個を想定

    var body: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .leading), count: 2)
        LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
            ForEach(0..<items.count, id: \.self) { i in
                HStack {
                    Text(items[i].0)
                        .font(.bestTen(size: 16))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Text(items[i].1)
                        .font(.bestTen(size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - ハート行（なつき度）
struct HeartRow: View {
    let count: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .foregroundColor(.red)
                    .shadow(radius: 1)
            }
        }
    }
}

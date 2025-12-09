//
//  DiceGlitchView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/12/03.
//

import SwiftUI
import Combine

/// Kavsoft風グリッチダイス表示
struct DiceGlitchView: View {
    enum Mode {
        case rolling
        case pinned
    }

    let number: Int
    let duration: TimeInterval
    let mode: Mode
    let onFinished: () -> Void

    @State private var startDate: Date? = nil
    @State private var elapsed: TimeInterval = 0
    @State private var didFinishAnimation = false
    @State private var displayedNumber: Int = 1
    @State private var isLocked = false

    private let shuffleDuration: TimeInterval = 2.0
    private var totalDuration: TimeInterval { shuffleDuration + duration }
    private var randomRange: ClosedRange<Int> {
        let maxVal = max(6, number)
        return 1...maxVal
    }

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var phase: CGFloat {
        CGFloat(elapsed)
    }

    init(number: Int,
         duration: TimeInterval,
         mode: Mode = .rolling,
         onFinished: @escaping () -> Void = {}) {
        self.number = number
        self.duration = duration
        self.mode = mode
        self.onFinished = onFinished
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let textSize = size * 0.58

            ZStack {
                DigitalStripeBackground()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
                    )

                if mode == .rolling {
                    ScanlineOverlay(phase: phase)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .blendMode(.overlay)
                        .opacity(0.55)
                }

                mainText(fontSize: textSize)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if mode == .rolling && !isLocked {
                    glitchLayer(fontSize: textSize, color: .cyan, xSeed: 0.0, ySeed: 0.3)
                    glitchLayer(fontSize: textSize, color: .green, xSeed: 1.3, ySeed: -0.4)
                }
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(timer) { date in
            guard mode == .rolling, !didFinishAnimation else { return }

            if startDate == nil {
                startDate = date
                elapsed = 0
                displayedNumber = Int.random(in: randomRange)
                return
            }
            guard let start = startDate else { return }

            let newElapsed = date.timeIntervalSince(start)

            if newElapsed < shuffleDuration {
                displayedNumber = Int.random(in: randomRange)
            } else if !isLocked {
                isLocked = true
                displayedNumber = number
            }

            if newElapsed >= totalDuration {
                didFinishAnimation = true
                onFinished()
                elapsed = totalDuration
            } else {
                elapsed = newElapsed
            }
        }
    }

    private func mainText(fontSize: CGFloat) -> some View {
        Text("\(mode == .rolling ? displayedNumber : number)")
            .font(.bestTen(size: fontSize))
            .fontWeight(.black)
            .tracking(4)
            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 2)
    }

    private func glitchLayer(fontSize: CGFloat, color: Color, xSeed: CGFloat, ySeed: CGFloat) -> some View {
        mainText(fontSize: fontSize)
            .foregroundColor(color)
            .blendMode(.screen)
            .offset(
                x: sin(phase * 40 + xSeed * 5) * 6,
                y: cos(phase * 25 + ySeed * 5) * 3
            )
            .opacity(0.65 + 0.35 * Double(abs(sin(phase * 50 + xSeed))))
            .mask(
                GlitchBandMask(
                    phase: phase,
                    bandCount: 6,
                    xSeed: xSeed,
                    ySeed: ySeed
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 横のバーがガタガタ動きながらテキストを切り取るマスク
private struct GlitchBandMask: View {
    let phase: CGFloat
    let bandCount: Int
    let xSeed: CGFloat
    let ySeed: CGFloat

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let bandH = h / CGFloat(bandCount)

            // ▼ 縦スクロール用の設定
            let step = bandH                // バンド1本ぶんの高さ
            let count = bandCount + 2       // ラップ用にちょい多め
            let speed: CGFloat = 40         // 縦に流れる速さ（ポイント/秒くらいのイメージ）

            // phase を使って上下にずらす量を計算
            // 正の値で「上→下に流れる」感じ
            let rawOffset = phase * speed
            let scroll = rawOffset.truncatingRemainder(dividingBy: step)

            ZStack(alignment: .topLeading) {
                ForEach(0..<count, id: \.self) { i in
                    let t = phase + CGFloat(i) * 0.5
                    // 各バンドごとに横方向のシフト量を変える
                    let shiftX = sin(t * 20 + xSeed * 10) * bandH * 0.6

                    // 縦位置：元の位置 + スクロール
                    let baseY = step * CGFloat(i) + bandH * 0.1
                    let y = baseY + scroll   // ← 上から下に流れる

                    Rectangle()
                        .frame(
                            width: geo.size.width * 1.4,
                            height: bandH * 0.8
                        )
                        .offset(
                            x: shiftX - geo.size.width * 0.2,
                            y: y
                        )
                }
            }
        }
        .compositingGroup()
    }
}

/// うっすら入るスキャンライン（横縞・上から下へ流れる）
private struct ScanlineOverlay: View {
    let phase: CGFloat   // ← 追加

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let stripeH: CGFloat = 2
            let gap: CGFloat = 2
            let step = stripeH + gap
            let count = Int(h / step) + 2   // 少し多めに描いておく

            // phase を使って縞全体を下方向にずらす
            let speed: CGFloat = 40         // 数値を上げると速くなる
            let rawOffset = phase * speed
            // 1ステップ分でループするように剰余を取る
            let scroll = rawOffset.truncatingRemainder(dividingBy: step)

            ZStack(alignment: .top) {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: stripeH)
                        .offset(y: CGFloat(i) * step)
                }
            }
            .offset(y: scroll)   // 上から下に流れていく
        }
    }
}

private struct DigitalStripeBackground: View {
    var body: some View {
        GeometryReader { geo in
            let stripeHeight: CGFloat = 3
            let gap: CGFloat = 1.5
            let step = stripeHeight + gap
            let count = Int(geo.size.height / step) + 2
            let stripeColor = Color(red: 0.35, green: 0.95, blue: 0.45).opacity(0.8)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.65)

                ForEach(0..<count, id: \.self) { idx in
                    Rectangle()
                        .fill(stripeColor)
                        .frame(height: stripeHeight)
                        .offset(y: CGFloat(idx) * step)
                }
            }
        }
    }
}

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
    let number: Int
    let duration: TimeInterval
    let onFinished: () -> Void

    @State private var startDate: Date? = nil
    @State private var elapsed: TimeInterval = 0

    // 60fps くらいで更新
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var phase: CGFloat {
        CGFloat(elapsed)
    }

    var body: some View {
        ZStack {
            // 背景パネル
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.8), // 中央が一番濃い
                            Color.green.opacity(0.0)  // 外側は完全に透明
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90   // 150x150 に対してちょうどいいくらい
                    )
                )
                .frame(width: 150, height: 150)
                .shadow(radius: 20)

            // スキャンラインっぽい縞模様
            ScanlineOverlay(phase: phase)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .blendMode(.overlay)
                .opacity(0.6)

            // ベースのテキスト
            mainText
                .foregroundStyle(.white)

            // RGBずれ＋横バンドによるグリッチレイヤー
            glitchLayer(color: .cyan,  xSeed: 0.0,  ySeed: 0.3)
            glitchLayer(color: .green,   xSeed: 1.3,  ySeed: -0.4)
        }
        .onReceive(timer) { date in
            if startDate == nil {
                startDate = date
                elapsed = 0
                return
            }
            guard let start = startDate else { return }

            let newElapsed = date.timeIntervalSince(start)

            if newElapsed >= duration {
                // 終了
                onFinished()
                // 以後できるだけ負荷を減らす（描画は残り1フレームでほぼ消える）
                elapsed = duration
            } else {
                elapsed = newElapsed
            }
        }
    }

    private var mainText: some View {
        Text("\(number)")
            .font(.system(size: 80, weight: .black, design: .rounded))
            .tracking(4)
    }

    /// グリッチ用レイヤー（Kavsoft風：横バンドごとに左右にズレる＋色ずれ）
    private func glitchLayer(color: Color, xSeed: CGFloat, ySeed: CGFloat) -> some View {
        mainText
            .foregroundColor(color)
            .blendMode(.screen)
            .offset(
                x: sin(phase * 40 + xSeed * 5) * 6,
                y: cos(phase * 25 + ySeed * 5) * 3
            )
            .opacity(0.6 + 0.4 * Double(abs(sin(phase * 50 + xSeed))))
            // 横バンドごとのマスクで「ガタガタ切れた文字」にする
            .mask(
                GlitchBandMask(
                    phase: phase,
                    bandCount: 6,
                    xSeed: xSeed,
                    ySeed: ySeed
                )
            )
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


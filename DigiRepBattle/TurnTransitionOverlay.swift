//
//  TurnTransitionOverlay.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/14.
//

import SwiftUI

struct TurnTransitionOverlay: View {
    let bandTopImage: String = "bandTop"
    let bandBottomImage: String = "bandBottom"
    let title: String = "NEXT TURN"

    @State private var textOffsetX: CGFloat = 0
    @State private var hasStarted = false
    @State private var pulseTop: Double = 1.0
    @State private var pulseBottom: Double = 1.0

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height

            // —— 高さ配分（上限付きで見切れ防止）——
            let bandH: CGFloat   = min(H * 0.06, 50)   // 上下帯
            let centerH: CGFloat = min(H * 0.22, 130)  // 中央帯
            let totalH: CGFloat  = bandH * 2 + centerH

            ZStack {
                Color.black.opacity(0.6)

                VStack(spacing: 0) {
                    InfiniteSlidingStrip(
                        imageName: bandTopImage,
                        containerWidth: W,
                        height: bandH,
                        direction: .left,
                        opacity: pulseTop
                    )
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: centerH)
                    InfiniteSlidingStrip(
                        imageName: bandBottomImage,
                        containerWidth: W,
                        height: bandH,
                        direction: .right,
                        opacity: pulseBottom
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: totalH)
                .clipped()

                Text(title)
                    .font(.bestTen(size: min(W, H) * 0.12))
                    .fontWeight(.heavy)
                    .kerning(2)
                    .foregroundColor(.white)
                    .shadow(radius: 12)
                    .offset(x: textOffsetX)
            }
            .onAppear {
                guard !hasStarted else { return }
                hasStarted = true

                // 帯の点滅のみ（スクロールはTimelineView側で常時更新）
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseTop = 0.35
                    pulseBottom = 0.35
                }

                textOffsetX = W * 2
                withAnimation(.easeOut(duration: 0.75)) { textOffsetX = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation(.linear(duration: 2.5)) {
                        textOffsetX = -min(40, W * 0.06)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.25) {
                    withAnimation(.easeIn(duration: 0.75)) {
                        textOffsetX = -W * 2
                    }
                }
            }
            .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

struct InfiniteSlidingStrip: View {
    enum Direction { case left, right }

    let imageName: String
    let containerWidth: CGFloat
    let height: CGFloat
    let direction: Direction
    let opacity: Double
    let speed: CGFloat = 160 // px/秒 ※好みで

    var body: some View {
        TimelineView(.animation) { timeline in
            // 経過時間からオフセット算出
            let t = timeline.date.timeIntervalSinceReferenceDate
            let d = CGFloat(t) * speed
            let shift = d.truncatingRemainder(dividingBy: containerWidth)
            let x = (direction == .left) ? -shift : shift

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: containerWidth, height: height)
                        .clipped()
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: containerWidth, height: height)
                        .clipped()
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: containerWidth, height: height)
                        .clipped()
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: containerWidth, height: height)
                        .clipped()
                }
                .offset(x: x)
            }
            .frame(width: containerWidth, height: height)
            .clipped()
            .opacity(opacity)
        }
    }
}


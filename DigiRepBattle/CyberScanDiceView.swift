//
//  CyberScanDiceView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/18.
//

import SwiftUI

struct CyberScanDiceView: View {
    let result: Int
    let duration: Double = 2

    @State private var displayNumber: Int = 1
    @State private var isLocked = false
    @State private var scanOffset: CGFloat = -50

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    AngularGradient(
                    gradient: Gradient(colors: [.cyan, .mint, .blue, .cyan]),
                    center: .center
                    ),
                    lineWidth: 4
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                )
                .shadow(radius: 10)

            ZStack {
                // スキャンライン（ホログラムっぽく）
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.cyan.opacity(0.9), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 190)
                    .offset(y: scanOffset)
                    .blendMode(.screen)
                    .clipped()
                    .mask(
                        RoundedRectangle(cornerRadius: 1)
                    )

                // 中央の数字
                Text("\(displayNumber)")
                    .font(.bestTen(size: 110))
                    .fontWeight(.heavy)
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan, radius: 10)
                    .overlay(
                    Text("\(displayNumber)")
                        .font(.bestTen(size: 110))
                        .fontWeight(.heavy)
                        .foregroundColor(.white.opacity(0.5))
                        .blur(radius: 4)
                    )
                    .scaleEffect(isLocked ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.3), value: isLocked)
            }
            .padding(6)
        }
        .frame(width: 200, height: 200)
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // スキャンライン
        withAnimation(.linear(duration: duration)) {
            scanOffset = 300
        }

        // ランダム数字 → 結果確定
        let start = Date()
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= duration {
                displayNumber = result
                isLocked = true
                timer.invalidate()
            } else {
                displayNumber = Int.random(in: 1...6)
            }
        }
    }
}

#Preview {
    CyberScanDiceView(result: 1)
}

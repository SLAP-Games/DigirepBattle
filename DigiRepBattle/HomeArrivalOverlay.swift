//
//  HomeArrivalOverlay.swift
//  DigiRepBattle
//

import SwiftUI

struct HomeArrivalOverlay: View {
    let size: CGFloat
    let trigger: UUID

    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.yellow.opacity(0.6), lineWidth: size * 0.06)
                .scaleEffect(animate ? 1.4 : 0.4)
                .opacity(animate ? 0.0 : 0.9)
            ForEach(0..<10, id: \.self) { idx in
                Capsule()
                    .fill(Color.yellow.opacity(0.85))
                    .frame(width: size * 0.04, height: size * 0.45)
                    .offset(y: -size * 0.2)
                    .rotationEffect(.degrees(Double(idx) / 10.0 * 360.0))
                    .scaleEffect(y: animate ? 1.1 : 0.3, anchor: .bottom)
                    .opacity(animate ? 0.0 : 0.95)
                    .blur(radius: 0.6)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .onAppear {
            restartAnimation()
        }
        .onChange(of: trigger) { _, _ in
            restartAnimation()
        }
    }

    private func restartAnimation() {
        animate = false
        withAnimation(.easeOut(duration: 2.0)) {
            animate = true
        }
    }
}

//
//  LevelUpOverlay.swift
//  DigiRepBattle
//

import SwiftUI

struct LevelUpOverlay: View {
    let size: CGFloat
    let trigger: UUID

    @State private var waveProgress = false
    @State private var arrowProgress = false

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(Color.orange.opacity(0.7), lineWidth: size * 0.05)
                .scaleEffect(waveProgress ? 1.4 : 0.3)
                .opacity(waveProgress ? 0.0 : 0.9)
                .blur(radius: size * 0.02)

            ArrowShape()
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: size * 0.24, height: size * 0.6)
                .offset(y: arrowProgress ? -size * 0.3 : size * 0.25)
                .opacity(arrowProgress ? 0.0 : 1.0)
                .blur(radius: size * 0.01)
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
        waveProgress = false
        arrowProgress = false
        withAnimation(.easeOut(duration: 1.2)) {
            waveProgress = true
        }
        withAnimation(.easeOut(duration: 1.0)) {
            arrowProgress = true
        }
    }
}

private struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stemWidth = rect.width * 0.4
        let stemHeight = rect.height * 0.55
        let stemX = (rect.width - stemWidth) / 2
        let arrowHeight = rect.height * 0.45

        // Stem
        path.addRect(CGRect(x: stemX, y: rect.maxY - stemHeight, width: stemWidth, height: stemHeight))

        // Arrow head
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.minY + arrowHeight))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.minY + arrowHeight))
        path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.minY + arrowHeight + stemWidth * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.minY + arrowHeight + stemWidth * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.minY + arrowHeight))
        path.addLine(to: CGPoint(x: 0, y: rect.minY + arrowHeight))
        path.closeSubpath()
        return path
    }
}

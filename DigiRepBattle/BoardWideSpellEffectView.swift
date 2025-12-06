import SwiftUI
import Combine

enum BoardWideSpellEffectKind: Equatable {
    case storm
    case disaster
}

struct BoardWideSpellEffectView: View {
    let kind: BoardWideSpellEffectKind

    @State private var animate = false
    @State private var stormPulse = false
    @State private var lightningStates: [LightningState] = []
    @State private var lightningTimer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch kind {
                case .storm:
                    stormView(size: geo.size)
                case .disaster:
                    disasterView(size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                animate = true
                stormPulse = true
                refreshLightningStates(force: true)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onReceive(lightningTimer) { _ in
            guard kind == .disaster else { return }
            refreshLightningStates(force: true)
        }
    }

    @ViewBuilder
    private func stormView(size: CGSize) -> some View {
        let maxDim = max(size.width, size.height)
        ZStack {
            Color.black.opacity(0.25)
            RadialGradient(
                colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.05), .clear],
                center: .center,
                startRadius: 0,
                endRadius: maxDim * 0.8
            )

            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.cyan.opacity(0.2),
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 5
                    )
                    .frame(width: maxDim * 0.2,
                           height: maxDim * 0.2)
                    .scaleEffect(stormPulse ? 4.2 : 0.2)
                    .opacity(stormPulse ? 0 : 0.55 - Double(index) * 0.08)
                    .animation(
                        .easeOut(duration: 1.4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.25),
                        value: stormPulse
                    )
            }

            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: maxDim * 0.25, height: maxDim * 0.25)
                .blur(radius: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .blur(radius: 5)
                )
        }
    }

    @ViewBuilder
    private func disasterView(size: CGSize) -> some View {
        let width = size.width
        ZStack {
            LinearGradient(colors: [.black.opacity(0.65), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                .blur(radius: 20)

            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white.opacity(animate ? 0.15 : 0.05))
                .blendMode(.screen)
                .animation(
                    .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true),
                    value: animate
                )

            ForEach(Array(lightningStates.enumerated()), id: \.offset) { index, state in
                LightningBoltShape(bends: state.bends)
                    .stroke(Color.white.opacity(state.opacity), lineWidth: state.thickness)
                    .shadow(color: .yellow.opacity(state.opacity), radius: 12)
                    .frame(width: width * 0.28, height: size.height * 0.95)
                    .offset(x: CGFloat(index - 1) * width * 0.22 + state.xShift * width,
                            y: size.height * -0.04)
            }
        }
    }

    private func refreshLightningStates(force: Bool) {
        guard kind == .disaster else { return }
        if !force, !lightningStates.isEmpty { return }
        lightningStates = (0..<3).map { _ in LightningState.random() }
    }
}

private struct LightningBoltShape: Shape {
    var bends: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = rect.midX
        path.move(to: CGPoint(x: startX, y: rect.minY))
        let segments: [CGFloat] = [0.22, 0.45, 0.7, 0.9, 1.5]
        for (idx, progress) in segments.enumerated() {
            let bend = bends.indices.contains(idx) ? bends[idx] : 0
            let targetX = startX + bend * rect.width * 0.5
            let targetY = rect.minY + progress * rect.height
            path.addLine(to: CGPoint(x: targetX, y: targetY))
        }
        return path
    }
}

private struct LightningState {
    var xShift: CGFloat
    var thickness: CGFloat
    var bends: [CGFloat]
    var opacity: Double

    static func random() -> LightningState {
        LightningState(
            xShift: CGFloat.random(in: -0.15...0.15),
            thickness: CGFloat.random(in: 1.5...3.8),
            bends: (0..<5).map { _ in CGFloat.random(in: -0.3...0.3) },
            opacity: Double.random(in: 0.5...1.0)
        )
    }
}

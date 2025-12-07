import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum BoardWideSpellEffectKind: Equatable {
    case storm
    case disaster
    case cure
    case treasure
    case clairvoyance
}

struct BoardWideSpellEffectView: View {
    let kind: BoardWideSpellEffectKind

    @State private var animate = false
    @State private var stormPulse = false
    @State private var lightningStates: [LightningState] = []
    @State private var lightningTimer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()
    @State private var curePulse = false
    @State private var treasureGlowExpand = false
    @State private var treasureTrigger = UUID()
    @State private var clairvoyancePulse = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch kind {
                case .storm:
                    stormView(size: geo.size)
                case .disaster:
                    disasterView(size: geo.size)
                case .cure:
                    cureView(size: geo.size)
                case .treasure:
                    treasureView(size: geo.size)
                case .clairvoyance:
                    clairvoyanceView(size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                animate = true
                stormPulse = (kind == .storm)
                curePulse = (kind == .cure)
                refreshLightningStates(force: true)
                prepareTreasureEffectIfNeeded()
                prepareClairvoyanceEffectIfNeeded()
            }
            .onChange(of: kind) { oldValue, newValue in
                stormPulse = (kind == .storm)
                curePulse = (kind == .cure)
                if kind == .disaster {
                    refreshLightningStates(force: true)
                }
                prepareTreasureEffectIfNeeded()
                prepareClairvoyanceEffectIfNeeded()
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

    private func prepareTreasureEffectIfNeeded() {
        guard kind == .treasure else { return }
        treasureTrigger = UUID()
        treasureGlowExpand = false
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.1)) {
                treasureGlowExpand = true
            }
        }
    }

    private func prepareClairvoyanceEffectIfNeeded() {
        guard kind == .clairvoyance else { return }
        clairvoyancePulse = false
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.45)) {
                clairvoyancePulse = true
            }
        }
    }

    @ViewBuilder
    private func cureView(size: CGSize) -> some View {
        let maxDim = max(size.width, size.height)
        ZStack {
            Color.white.opacity(0.08)
                .blendMode(.screen)

            RadialGradient(colors: [Color.yellow.opacity(0.3), Color.white.opacity(0.05), .clear],
                           center: .center,
                           startRadius: 0,
                           endRadius: maxDim * 0.7)

            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.yellow.opacity(0.4), Color.white.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: maxDim * (0.2 + CGFloat(index) * 0.05),
                           height: maxDim * (0.2 + CGFloat(index) * 0.05))
                    .scaleEffect(curePulse ? 4.0 : 0.2)
                    .opacity(curePulse ? 0.0 : 0.6 - Double(index) * 0.1)
                    .animation(
                        .easeOut(duration: 1.1)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.15),
                        value: curePulse
                    )
            }

            Circle()
                .fill(Color.white.opacity(0.25))
                .frame(width: maxDim * 0.3, height: maxDim * 0.3)
                .blur(radius: 30)
                .overlay(
                    Circle()
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 2)
                        .blur(radius: 4)
                )
        }
    }

    @ViewBuilder
    private func treasureView(size: CGSize) -> some View {
        let maxDim = max(size.width, size.height)

        ZStack {
            Color.black.opacity(0.2)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(0.35),
                            Color.yellow.opacity(0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: maxDim * 0.8
                    )
                )
                .scaleEffect(treasureGlowExpand ? 2.5 : 0.4)
                .opacity(treasureGlowExpand ? 0.0 : 0.6)
                .animation(.easeOut(duration: 1.1), value: treasureGlowExpand)

            Circle()
                .fill(Color.yellow.opacity(0.25))
                .frame(width: maxDim * 0.6, height: maxDim * 0.6)
                .blur(radius: 45)
                .opacity(0.35)

            CoinBurstField(config: .treasureGlobal, trigger: treasureTrigger)
        }
    }

    @ViewBuilder
    private func clairvoyanceView(size: CGSize) -> some View {
        let maxDim = max(size.width, size.height)
        ZStack {
            Color.black.opacity(0.3)
            RadialGradient(
                colors: [
                    Color.purple.opacity(0.5),
                    Color.purple.opacity(0.15),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: maxDim * 0.9
            )
            .blendMode(.screen)

            Group {
                if AssetAvailability.hasClairvoyanceAsset {
                    Image("clairvoyance")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "eye.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(maxDim * 0.15)
                }
            }
            .frame(width: maxDim * 0.5, height: maxDim * 0.5)
            .shadow(color: Color.purple.opacity(0.8), radius: 25)
            .shadow(color: Color.white.opacity(0.4), radius: 10)
            .scaleEffect(clairvoyancePulse ? 1.05 : 0.85)
            .opacity(clairvoyancePulse ? 1.0 : 0.0)
        }
    }
}

private struct LightningBoltShape: Shape {
    var bends: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = rect.midX
        path.move(to: CGPoint(x: startX, y: rect.minY))
        let segments: [CGFloat] = [0.22, 0.45, 0.7, 0.9, 1.0]
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

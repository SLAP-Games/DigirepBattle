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
}

struct BoardWideSpellEffectView: View {
    let kind: BoardWideSpellEffectKind

    @State private var animate = false
    @State private var stormPulse = false
    @State private var lightningStates: [LightningState] = []
    @State private var lightningTimer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()
    @State private var curePulse = false
    @State private var treasureCoins: [TreasureCoin] = []
    @State private var treasureStartDate: Date = Date()
    @State private var treasureGlowExpand = false

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
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                animate = true
                stormPulse = (kind == .storm)
                curePulse = (kind == .cure)
                refreshLightningStates(force: true)
                prepareTreasureEffectIfNeeded()
            }
            .onChange(of: kind) { oldValue, newValue in
                stormPulse = (kind == .storm)
                curePulse = (kind == .cure)
                if kind == .disaster {
                    refreshLightningStates(force: true)
                }
                prepareTreasureEffectIfNeeded()
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
        treasureStartDate = Date()
        treasureCoins = (0..<25).map { _ in TreasureCoin.random() }
        treasureGlowExpand = false
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 1.1)) {
                treasureGlowExpand = true
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
        let startPoint = CGPoint(x: size.width / 2, y: size.height * 0.85)
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

            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let elapsed = max(0, timeline.date.timeIntervalSince(treasureStartDate))
                ZStack {
                    ForEach(treasureCoins) { coin in
                        if let state = coin.state(at: elapsed, canvasSize: size, origin: startPoint) {
                            CoinImageView(size: state.size)
                                .rotation3DEffect(state.rotation3D, axis: state.axis)
                                .rotationEffect(state.zRotation)
                                .position(state.position)
                                .opacity(state.opacity)
                                .shadow(color: Color.yellow.opacity(0.4), radius: 6, x: 0, y: 0)
                        }
                    }
                }
            }
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

private struct TreasureCoinState {
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let rotation3D: Angle
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let zRotation: Angle
}

private struct TreasureCoin: Identifiable {
    let id = UUID()
    let horizontalDirection: CGFloat
    let horizontalDistance: CGFloat
    let peakHeight: CGFloat
    let duration: Double
    let delay: Double
    let spinSpeed: Double
    let axisX: CGFloat
    let axisY: CGFloat
    let baseSize: CGFloat
    let initialTilt: Double
    let initialZRotation: Double
    let zRotationSpeed: Double

    static func random() -> TreasureCoin {
        TreasureCoin(
            horizontalDirection: Bool.random() ? 1 : -1,
            horizontalDistance: .random(in: 0.25...0.6),
            peakHeight: .random(in: 0.25...0.45),
            duration: .random(in: 0.9...1.3),
            delay: .random(in: 0...0.3),
            spinSpeed: .random(in: 1.6...3.2),
            axisX: .random(in: -0.4...0.4),
            axisY: .random(in: 0.4...1.0),
            baseSize: .random(in: 0.045...0.08),
            initialTilt: Double.random(in: 0...180),
            initialZRotation: Double.random(in: 0...180),
            zRotationSpeed: Double.random(in: -1.0...1.0)
        )
    }

    func state(at elapsed: TimeInterval,
               canvasSize: CGSize,
               origin: CGPoint) -> TreasureCoinState? {
        let local = elapsed - delay
        guard local >= 0 else { return nil }
        guard local <= duration else { return nil }
        let progress = max(0, min(1, local / duration))
        let ease = easeOutQuad(progress)
        let horizontalTravel = horizontalDistance * canvasSize.width * 0.45
        let x = origin.x + horizontalDirection * horizontalTravel * CGFloat(ease)
        let height = peakHeight * canvasSize.height * 0.6
        let parabola = 4 * progress * (1 - progress)
        let y = origin.y - height * CGFloat(parabola) + CGFloat(progress) * canvasSize.height * 0.05
        let maxDim = max(canvasSize.width, canvasSize.height)
        let coinSize = maxDim * baseSize
        let opacity = Double(max(0, 1 - pow(progress, 1.4)))
        let rotationAngle = Angle.degrees(initialTilt + (spinSpeed * 360) * progress)
        let zAngle = Angle.degrees(initialZRotation + (zRotationSpeed * 180) * progress)

        let axisVector = normalizeAxis(x: axisX, y: axisY)

        return TreasureCoinState(
            position: CGPoint(x: x, y: y),
            size: coinSize,
            opacity: opacity,
            rotation3D: rotationAngle,
            axis: axisVector,
            zRotation: zAngle
        )
    }

    private func easeOutQuad(_ t: Double) -> Double {
        let inv = 1 - t
        return 1 - inv * inv
    }

    private func normalizeAxis(x: CGFloat, y: CGFloat) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let vector = CGVector(dx: x, dy: y)
        let magnitude = max(0.001, sqrt(vector.dx * vector.dx + vector.dy * vector.dy))
        return (x: vector.dx / magnitude, y: vector.dy / magnitude, z: 0.0)
    }
}

private struct CoinImageView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if AssetAvailability.hasCoinAsset {
                Image("coin")
                    .resizable()
                    .renderingMode(.original)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

private enum AssetAvailability {
    static let hasCoinAsset: Bool = {
        #if canImport(UIKit)
        return UIImage(named: "coin") != nil
        #elseif canImport(AppKit)
        return NSImage(named: NSImage.Name("coin")) != nil
        #else
        return true
        #endif
    }()
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

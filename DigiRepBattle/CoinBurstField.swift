import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct CoinBurstConfig: Equatable {
    var count: Int
    var startPoint: UnitPoint
    var horizontalDistanceRange: ClosedRange<CGFloat>
    var peakHeightRange: ClosedRange<CGFloat>
    var durationRange: ClosedRange<Double>
    var delayRange: ClosedRange<Double>
    var baseSizeRange: ClosedRange<CGFloat>
    var spinSpeedRange: ClosedRange<Double>
    var axisXRange: ClosedRange<CGFloat>
    var axisYRange: ClosedRange<CGFloat>
    var zRotationSpeedRange: ClosedRange<Double>
    var verticalDriftRange: ClosedRange<CGFloat>
    var opacityPower: Double
}

extension CoinBurstConfig {
    static let treasureGlobal = CoinBurstConfig(
        count: 25,
        startPoint: UnitPoint(x: 0.5, y: 0.85),
        horizontalDistanceRange: 0.25...0.6,
        peakHeightRange: 0.25...0.45,
        durationRange: 0.9...1.3,
        delayRange: 0...0.3,
        baseSizeRange: 0.045...0.08,
        spinSpeedRange: 1.6...3.2,
        axisXRange: -0.4...0.4,
        axisYRange: 0.4...1.0,
        zRotationSpeedRange: -1.0...1.0,
        verticalDriftRange: 0.02...0.08,
        opacityPower: 1.4
    )

    static let plunderLocal = CoinBurstConfig(
        count: 25,
        startPoint: UnitPoint(x: 0.5, y: 0.15),
        horizontalDistanceRange: 0.15...0.35,
        peakHeightRange: 0.28...0.48,
        durationRange: 0.75...1.05,
        delayRange: 0...0.18,
        baseSizeRange: 0.16...0.24,
        spinSpeedRange: 1.2...2.4,
        axisXRange: -0.35...0.35,
        axisYRange: 0.35...0.9,
        zRotationSpeedRange: -0.8...0.8,
        verticalDriftRange: 0.03...0.08,
        opacityPower: 1.35
    )

    static let goldSkill = CoinBurstConfig(
        count: 10,
        startPoint: UnitPoint(x: 0.5, y: 0.2),
        horizontalDistanceRange: 0.12...0.3,
        peakHeightRange: 0.25...0.4,
        durationRange: 0.8...1.0,
        delayRange: 0...0.1,
        baseSizeRange: 0.12...0.18,
        spinSpeedRange: 1.2...2.0,
        axisXRange: -0.3...0.3,
        axisYRange: 0.2...0.8,
        zRotationSpeedRange: -0.8...0.8,
        verticalDriftRange: 0.02...0.06,
        opacityPower: 1.3
    )
}

struct CoinBurstField: View {
    let config: CoinBurstConfig
    let trigger: UUID

    @State private var coins: [CoinParticle] = []
    @State private var startDate = Date()
    @State private var containerSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let elapsed = max(0, timeline.date.timeIntervalSince(startDate))
                let size = geo.size

                ZStack {
                    ForEach(coins) { coin in
                        if let state = coin.state(at: elapsed, canvasSize: size, config: config) {
                            CoinImageView(size: state.size)
                                .rotation3DEffect(state.rotation3D, axis: state.axis)
                                .rotationEffect(state.zRotation)
                                .position(state.position)
                                .opacity(state.opacity)
                                .shadow(color: Color.yellow.opacity(0.35), radius: 6)
                        }
                    }
                }
            }
            .onAppear {
                if containerSize != geo.size {
                    containerSize = geo.size
                }
                resetParticles()
            }
            .onChange(of: geo.size) { _, newSize in
                containerSize = newSize
                resetParticles()
            }
            .onChange(of: trigger) { _, _ in
                resetParticles()
            }
            .onChange(of: config) { _, _ in
                resetParticles()
            }
        }
    }

    private func resetParticles() {
        guard containerSize.width > 0, containerSize.height > 0 else { return }
        startDate = Date()
        coins = (0..<max(1, config.count)).map { _ in CoinParticle(config: config) }
    }
}

private struct CoinParticleState {
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let rotation3D: Angle
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let zRotation: Angle
}

private struct CoinParticle: Identifiable {
    let id = UUID()
    let direction: CGFloat
    let horizontalDistance: CGFloat
    let peakHeight: CGFloat
    let duration: Double
    let delay: Double
    let spinSpeed: Double
    let axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    let baseSize: CGFloat
    let zRotationSpeed: Double
    let verticalDrift: CGFloat
    let opacityPower: Double

    init(config: CoinBurstConfig) {
        direction = Bool.random() ? 1 : -1
        horizontalDistance = CGFloat.random(in: config.horizontalDistanceRange)
        peakHeight = CGFloat.random(in: config.peakHeightRange)
        duration = Double.random(in: config.durationRange)
        delay = Double.random(in: config.delayRange)
        spinSpeed = Double.random(in: config.spinSpeedRange)
        let axisX = CGFloat.random(in: config.axisXRange)
        let axisY = CGFloat.random(in: config.axisYRange)
        axis = Self.normalizeAxis(x: axisX, y: axisY)
        baseSize = CGFloat.random(in: config.baseSizeRange)
        zRotationSpeed = Double.random(in: config.zRotationSpeedRange)
        verticalDrift = CGFloat.random(in: config.verticalDriftRange)
        opacityPower = config.opacityPower
    }

    func state(at elapsed: TimeInterval,
               canvasSize: CGSize,
               config: CoinBurstConfig) -> CoinParticleState? {
        let local = elapsed - delay
        guard local >= 0 else { return nil }
        guard local <= duration else { return nil }
        let progress = max(0, min(1, local / duration))
        let eased = easeOutQuad(progress)

        let origin = CGPoint(
            x: config.startPoint.x * canvasSize.width,
            y: config.startPoint.y * canvasSize.height
        )

        let horizontalTravel = horizontalDistance * canvasSize.width
        let x = origin.x + direction * horizontalTravel * CGFloat(eased)

        let peak = peakHeight * canvasSize.height
        let parabola = 4 * progress * (1 - progress)
        let y = origin.y - peak * CGFloat(parabola) + CGFloat(progress) * canvasSize.height * verticalDrift

        let maxDim = max(canvasSize.width, canvasSize.height)
        let size = maxDim * baseSize

        let opacity = max(0, 1 - pow(progress, opacityPower))
        let rotationAngle = Angle.degrees((spinSpeed * 360) * progress)
        let zAngle = Angle.degrees((zRotationSpeed * 180) * progress)

        return CoinParticleState(
            position: CGPoint(x: x, y: y),
            size: size,
            opacity: opacity,
            rotation3D: rotationAngle,
            axis: axis,
            zRotation: zAngle
        )
    }

    private func easeOutQuad(_ t: Double) -> Double {
        let inv = 1 - t
        return 1 - inv * inv
    }

    private static func normalizeAxis(x: CGFloat, y: CGFloat) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let magnitude = max(0.001, sqrt(x * x + y * y))
        return (x / magnitude, y / magnitude, 0.0)
    }
}

struct CoinImageView: View {
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

enum AssetAvailability {
    static func imageExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #elseif canImport(AppKit)
        return NSImage(named: NSImage.Name(name)) != nil
        #else
        return true
        #endif
    }

    static let hasCoinAsset: Bool = imageExists("coin")
    static let hasClairvoyanceAsset: Bool = imageExists("clairvoyance")
}

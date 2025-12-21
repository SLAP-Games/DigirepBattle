import SwiftUI
import SpriteKit

struct DeleteBugCountdownOverlay: View {
    let size: CGFloat
    let level: Int
    let trigger: UUID

    @State private var isVisible = false
    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0.0

    var body: some View {
        Image("deleteBug\(level)")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .allowsHitTesting(false)
            .onAppear { start() }
            .onChange(of: trigger) { _, _ in start() }
    }

    private func start() {
        scale = 0.6
        opacity = 0.9
        withAnimation(.easeOut(duration: 0.65)) {
            scale = 1.0
            opacity = 0.0
        }
    }
}

struct DeleteBugSmokeOverlay: View {
    let size: CGFloat
    let trigger: UUID
    @State private var scene: DeleteBugSmokeScene

    init(size: CGFloat, trigger: UUID) {
        self.size = size
        self.trigger = trigger
        _scene = State(initialValue: DeleteBugSmokeScene(size: CGSize(width: size, height: size)))
    }

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: size, height: size)
            .onChange(of: trigger) { _, _ in
                scene = DeleteBugSmokeScene(size: CGSize(width: size, height: size))
            }
            .allowsHitTesting(false)
    }
}

final class DeleteBugSmokeScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        runSmoke()
    }

    private func runSmoke() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "effectStar")
        emitter.position = CGPoint(x: size.width / 2, y: size.height / 2)
        emitter.particleBirthRate = 80
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 40
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -1.6
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.15
        emitter.particleScaleSpeed = -0.5
        emitter.particleColor = UIColor.gray.withAlphaComponent(0.8)
        emitter.particleColorBlendFactor = 1
        emitter.particleRotationRange = .pi * 2
        emitter.zPosition = 10
        addChild(emitter)

        let stop = SKAction.sequence([
            .wait(forDuration: 0.4),
            .run { emitter.particleBirthRate = 0 },
            .wait(forDuration: 0.6),
            .removeFromParent()
        ])
        emitter.run(stop) { [weak self] in
            self?.run(.sequence([.wait(forDuration: 0.2), .removeFromParent()]))
        }
    }
}

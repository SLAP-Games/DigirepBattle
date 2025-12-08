import SwiftUI

/// ボード上のクリーチャーを消す際のネオンライン演出
struct TileRemovalOverlay: View {
    let size: CGFloat
    let trigger: UUID

    @State private var progress: Double = 0
    @State private var isActive = false
    private let duration: Double = 0.85

    var body: some View {
        ZStack {
            TileRemovalGlow(progress: progress, isActive: isActive)
            TileRemovalNeonLine(progress: progress)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .onAppear { startAnimation() }
        .onChange(of: trigger) { _, _ in
            startAnimation()
        }
    }

    private func startAnimation() {
        progress = 0
        isActive = true

        withAnimation(.easeInOut(duration: duration)) {
            progress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isActive = false
        }
    }
}

private struct TileRemovalGlow: View {
    let progress: Double
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            let height = geo.size.height
            let remaining = max(0.0001, 1 - clamped)

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.25),
                    Color.cyan.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: geo.size.width, height: height)
            .scaleEffect(x: 1, y: remaining, anchor: .bottom)
            .opacity(isActive ? 0.8 : 0)
        }
    }
}

private struct TileRemovalNeonLine: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            let height = geo.size.height
            let width = geo.size.width
            let lineThickness = max(4, height * 0.08)
            let glowHeight = lineThickness * 3
            let yTop = (height - lineThickness) * clamped
            let lineCenter = yTop + lineThickness / 2
            let glowCenter = yTop + glowHeight / 2

            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.35),
                        Color.cyan.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: width, height: glowHeight)
                .position(x: width / 2, y: glowCenter)

                RoundedRectangle(cornerRadius: lineThickness / 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.2),
                                Color.cyan,
                                Color.cyan.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.9, height: lineThickness)
                    .shadow(color: Color.cyan.opacity(0.8), radius: 10)
                    .position(x: width / 2, y: lineCenter)
            }
        }
        .allowsHitTesting(false)
    }
}

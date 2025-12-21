import SwiftUI

struct GoldSkillOverlay: View {
    let amount: Int
    let trigger: UUID
    let size: CGFloat

    @State private var animateCoin = false

    var body: some View {
        ZStack {
            CoinBurstField(config: .goldSkill, trigger: trigger)
                .frame(width: size, height: size)

            VStack(spacing: 4) {
                Text("+\(amount)G")
                    .font(.bestTen(size: min(28, size * 0.22)))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.25)
                    .scaleEffect(animateCoin ? 1.1 : 0.9)
                    .opacity(animateCoin ? 1 : 0.6)
            }
        }
        .frame(width: size, height: size)
        .onAppear { pulse() }
        .onChange(of: trigger) { _, _ in pulse() }
        .allowsHitTesting(false)
    }

    private func pulse() {
        withAnimation(.easeInOut(duration: 0.4).repeatCount(3, autoreverses: true)) {
            animateCoin.toggle()
        }
    }
}

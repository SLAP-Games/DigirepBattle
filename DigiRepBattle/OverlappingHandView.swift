import SwiftUI

struct OverlappingHandView: View {
    let cards: [Card]
    @Binding var focusedIndex: Int
    @Binding var dragOffset: CGFloat
    var onTap: (Int) -> Void
    var onTapUp: (Int) -> Void
    var highlightCreatureCards: Bool = false

    @State private var dragStartIndex: Int = 0
    @State private var isDragging = false
    @State private var glowOpacity: Double = 0
    @State private var glowAnimating = false

    private let cardSize = CGSize(width: 90, height: 130)

    var body: some View {
        GeometryReader { geo in
            let spacing = spacingForHand(width: geo.size.width)
            let totalWidth = cardSize.width + spacing * CGFloat(max(cards.count - 1, 0))
            let startX = (geo.size.width - totalWidth) / 2

            ZStack {
                ForEach(Array(cards.enumerated()), id: \.offset) { entry in
                    let idx = entry.offset
                    let card = entry.element
                    cardView(card: card,
                             index: idx,
                             baseSpacing: spacing,
                             startX: startX,
                             canvasSize: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDragging {
                            dragStartIndex = focusedIndex
                            isDragging = true
                        }
                        dragOffset = value.translation.width

                        let delta = value.translation.width / max(spacing, 1)
                        let candidate = clampIndex(dragStartIndex + Int(delta.rounded()))
                        if candidate != focusedIndex {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                focusedIndex = candidate
                            }
                        }
                    }
                    .onEnded { value in
                        dragOffset = 0
                        isDragging = false
                        let isSwipeUp = value.translation.height < -40 && abs(value.translation.width) < 80
                        if isSwipeUp {
                            onTapUp(focusedIndex)
                        } else if abs(value.translation.height) < 10 && abs(value.translation.width) < 10 {
                            onTap(focusedIndex)
                        }
                    }
            )
            .onAppear(perform: updateGlowAnimation)
            .onChange(of: highlightCreatureCards) { _, _ in
                updateGlowAnimation()
            }
        }
    }

    private func cardView(card: Card,
                          index: Int,
                          baseSpacing: CGFloat,
                          startX: CGFloat,
                          canvasSize: CGSize) -> some View {
        let xPosition = startX + cardSize.width / 2 + CGFloat(index) * baseSpacing
        let baseY = canvasSize.height - (cardSize.height / 2)
        let isFocused = focusedIndex == index

        let shouldHighlight = highlightCreatureCards && card.kind == .creature
        let currentGlow = shouldHighlight ? glowOpacity : 0

        return CardView(card: card)
            .frame(width: cardSize.width, height: cardSize.height)
            .scaleEffect(isFocused ? 1.1 : 0.92)
            .position(x: xPosition, y: baseY)
            .offset(y: isFocused ? -22 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.yellow.opacity(currentGlow), lineWidth: shouldHighlight ? 3 : 0)
                    .shadow(color: Color.yellow.opacity(currentGlow),
                            radius: shouldHighlight ? (10 + 8 * currentGlow) : 0)
            )
            .shadow(color: .black.opacity(isFocused ? 0.35 : 0.15),
                    radius: isFocused ? 10 : 4,
                    y: 6)
            .zIndex(zPriority(for: index))
            .animation(.easeInOut(duration: 0.12), value: focusedIndex)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            focusedIndex = index
                        }
                        onTap(index)
                    }
            )
    }

    private func spacingForHand(width: CGFloat) -> CGFloat {
        guard cards.count > 1 else { return 0 }
        let raw = (width - cardSize.width) / CGFloat(cards.count - 1)
        return max(16, min(42, raw))
    }

    private func clampIndex(_ value: Int) -> Int {
        guard !cards.isEmpty else { return 0 }
        return min(max(value, 0), cards.count - 1)
    }

    private func zPriority(for index: Int) -> Double {
        guard !cards.isEmpty else { return 0 }
        if index == focusedIndex { return Double(cards.count) }

        let rightCount = max(cards.count - focusedIndex - 1, 0)
        let orderPosition: Int
        if index > focusedIndex {
            orderPosition = index - focusedIndex
        } else {
            orderPosition = rightCount + (focusedIndex - index)
        }

        return Double(cards.count - orderPosition)
    }

    private func updateGlowAnimation() {
        if highlightCreatureCards {
            startGlowAnimation()
        } else {
            stopGlowAnimation()
        }
    }

    private func startGlowAnimation() {
        guard !glowAnimating else { return }
        glowAnimating = true
        glowOpacity = 0
        withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            glowOpacity = 1
        }
    }

    private func stopGlowAnimation() {
        guard glowAnimating else { return }
        glowAnimating = false
        withAnimation(.easeOut(duration: 0.2)) {
            glowOpacity = 0
        }
    }
}

private struct OverlappingHandViewPreviewContainer: View {
    @State private var focusedIndex = 2
    @State private var dragOffset: CGFloat = 0

    private let previewCards: [Card] = [
        .creature(id: "c1", name: "Frog", symbol: "🐸", stats: .defaultFrog),
        .creature(id: "c2", name: "Gecko", symbol: "🦎", stats: .defaultGecko),
        .creature(id: "c3", name: "Croc", symbol: "🐊", stats: .defaultCrocodile),
        .spell(id: "s1", name: "Storm", symbol: "☁️", effect: .damageAnyCreature(50)),
        .spell(id: "s2", name: "Poison", symbol: "☠️", effect: .poisonAnyCreature)
    ]

    var body: some View {
        OverlappingHandView(cards: previewCards,
                            focusedIndex: $focusedIndex,
                            dragOffset: $dragOffset,
                            onTap: { _ in },
                            onTapUp: { _ in })
        .frame(height: 220)
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

#if DEBUG
struct OverlappingHandView_Previews: PreviewProvider {
    static var previews: some View {
        OverlappingHandViewPreviewContainer()
            .previewLayout(.sizeThatFits)
    }
}
#endif

//
//  PanZoomContainer.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct PanZoomContainer<Content: View>: View {
    @GestureState private var dragOffset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    @GestureState private var pinchScale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0

    let minScale: CGFloat
    let maxScale: CGFloat
    let content: () -> Content

    init(minScale: CGFloat = 0.6, maxScale: CGFloat = 2.0, @ViewBuilder content: @escaping () -> Content) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let drag = DragGesture()
                .updating($dragOffset) { value, st, _ in st = value.translation }
                .onEnded { value in
                    baseOffset.width  += value.translation.width
                    baseOffset.height += value.translation.height
                }

            let pinch = MagnificationGesture()
                .updating($pinchScale) { value, st, _ in
                    st = value
                }
                .onEnded { value in
                    baseScale = (baseScale * value).clamped(to: minScale...maxScale)
                }

            // 画面中央（ビュー中央）
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let currentScale = (baseScale * pinchScale).clamped(to: minScale...maxScale)
            let currentOffset = CGSize(
                width:  baseOffset.width  + dragOffset.width,
                height: baseOffset.height + dragOffset.height
            )

            ZStack {
                Color.clear
                content()
                    // 変換順序:  -center → scale → +center → offset
                    .transformEffect(
                        CGAffineTransform(translationX: -center.x, y: -center.y)
                            .scaledBy(x: currentScale, y: currentScale)
                            .translatedBy(x: center.x, y: center.y)
                            .translatedBy(x: currentOffset.width, y: currentOffset.height)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(SimultaneousGesture(drag, pinch))
        }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

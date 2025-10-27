//
//  RingBoardView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct RingBoardView: View {
    let sideCount: Int = 5
    var tileCount: Int { 4 * (sideCount - 1) }
    var tiles: [RingTile] { (0..<tileCount).map { RingTile(index: $0) } }

    let tileSize: CGFloat = 80
    let gap: CGFloat = 8

    // 入力
    let p1Pos: Int
    let p2Pos: Int
    let owner: [Int?]
    let level: [Int]
    let creatureSymbol: [String?]
    let toll: (Int) -> Int

    var body: some View {
        PanZoomContainer {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                let step = tileSize + gap
                let span = CGFloat(sideCount - 1)
                let half = span / 2

                ZStack {
                    Rectangle()
                        .stroke(.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6,6]))
                        .frame(width: step * span, height: step * span)
                        .position(center)

                    ForEach(tiles) { t in
                        let g = gridCoord(for: t.index, sideCount: sideCount)
                        let x = center.x + (CGFloat(g.x) - half) * step
                        let y = center.y + (CGFloat(g.y) - half) * step

                        TileView(index: t.index,
                                 size: tileSize,
                                 hasP1: t.index == p1Pos,
                                 hasP2: t.index == p2Pos,
                                 owner: owner[t.index],
                                 level: level[t.index],
                                 creatureSymbol: creatureSymbol[t.index],
                                 toll: toll(t.index))
                            .position(x: x, y: y)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func gridCoord(for index: Int, sideCount s: Int) -> (x: Int, y: Int) {
        let perSide = s - 1
        switch index {
        case 0..<perSide:                         return (index, 0)
        case perSide..<(perSide * 2):             return (s - 1, index - perSide)
        case (perSide * 2)..<(perSide * 3):       return (s - 1 - (index - perSide * 2), s - 1)
        default:                                  return (0, s - 1 - (index - perSide * 3))
        }
    }
}

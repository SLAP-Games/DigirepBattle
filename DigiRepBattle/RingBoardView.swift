//
//  RingBoardView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

// 素朴な整数座標
private struct I2: Hashable {
    var x: Int
    var y: Int
}

private struct BoardNode: Identifiable, Hashable {
    let id: Int          // 0..N-1（TileViewの index に相当）
    let grid: I2         // 論理グリッド座標（描画時にスケーリング）
    var neighbors: [Int] // 接続先（分岐あり）
}

struct RingBoardView: View {
    // === レイアウト ===
    let sideCount: Int = 5
    let tileSize: CGFloat = 80
    let gap: CGFloat = 8

    // === 入力（従来互換） ===
    let p1Pos: Int
    let p2Pos: Int
    let owner: [Int?]
    let level: [Int]
    let creatureSymbol: [String?]
    let toll: (Int) -> Int
    let hp: [Int]
    let hpMax: [Int]

    // ===（任意）分岐UIを使う場合のフック ===
    var branchSource: Int? = nil
    var branchCandidates: [Int] = []
    var onPickBranch: ((Int) -> Void)? = nil

    // 角を重ねた正方形×2 のグラフ
    private var graph: [BoardNode] {
        makeOverlappedSquareGraph(side: sideCount)
    }

    var body: some View {
        PanZoomContainer {
            GeometryReader { geo in
                let step = tileSize + gap

                // グリッド境界→中央配置
                let (minX, maxX, minY, maxY) = bounds(graph.map { $0.grid })
                let spanX = CGFloat(maxX - minX)
                let spanY = CGFloat(maxY - minY)
                let boardSize = CGSize(width: (spanX + 1) * step, height: (spanY + 1) * step)
                let origin = CGPoint(
                    x: (geo.size.width - boardSize.width) / 2,
                    y: (geo.size.height - boardSize.height) / 2
                )

                ZStack {
                    // 背景ガイド
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6,6]))
                        .frame(width: boardSize.width, height: boardSize.height)
                        .position(x: origin.x + boardSize.width/2, y: origin.y + boardSize.height/2)

                    // エッジ（接続線）。重複描画を避けるため a<b のみ
                    Path { p in
                        for node in graph {
                            let a = node.id
                            let aPos = point(for: node.grid, minX: minX, minY: minY, step: step, origin: origin, tileSize: tileSize)
                            for b in node.neighbors where b > a {
                                let bPos = point(for: graph[b].grid, minX: minX, minY: minY, step: step, origin: origin, tileSize: tileSize)
                                p.move(to: aPos)
                                p.addLine(to: bPos)
                            }
                        }
                    }
                    .stroke(.secondary.opacity(0.35), lineWidth: 2)

                    // タイル
                    ForEach(graph) { node in
                        let idx = node.id
                        let pos = point(for: node.grid, minX: minX, minY: minY, step: step, origin: origin, tileSize: tileSize)

                        // 互換安全：配列は旧16マス想定でもクラッシュしないようにガード
                        let safeOwner = owner.indices.contains(idx) ? owner[idx] : nil
                        let safeLevel = level.indices.contains(idx) ? level[idx] : 0
                        let safeSymbol = creatureSymbol.indices.contains(idx) ? creatureSymbol[idx] : nil
                        let safeHp = hp.indices.contains(idx) ? hp[idx] : nil
                        let safeHpMax = hpMax.indices.contains(idx) ? hpMax[idx] : nil

                        // 互換安全：owner.count を“旧ボードの最大添字”の目安にし、
                        // 越えた分は toll を呼ばず 0 を返す（内部の out-of-range を防ぐ）
                        let safeToll: Int = (idx < owner.count) ? toll(idx) : 0

                        TileView(index: idx,
                                 size: tileSize,
                                 hasP1: idx == p1Pos,
                                 hasP2: idx == p2Pos,
                                 owner: safeOwner,
                                 level: safeLevel,
                                 creatureSymbol: safeSymbol,
                                 toll: safeToll,
                                 hp: safeHp,
                                 hpMax: safeHpMax
                        )
                        .position(pos)
                    }

                    // 分岐選択UI（使う場合のみ）
                    if let src = branchSource,
                       let srcNode = graph.first(where: { $0.id == src }),
                       !branchCandidates.isEmpty
                    {
                        let srcPos = point(for: srcNode.grid, minX: minX, minY: minY, step: step, origin: origin, tileSize: tileSize)
                        ForEach(branchCandidates, id: \.self) { cand in
                            let targetPos = point(for: graph[cand].grid, minX: minX, minY: minY, step: step, origin: origin, tileSize: tileSize)
                            let mid = CGPoint(x: (srcPos.x + targetPos.x) / 2, y: (srcPos.y + targetPos.y) / 2)

                            Button {
                                onPickBranch?(cand)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrowtriangle.forward.fill")
                                        .rotationEffect(angle(from: srcPos, to: targetPos))
                                        .font(.system(size: 16, weight: .bold))
                                    Text("\(cand + 1)")
                                        .font(.caption2).bold()
                                }
                                .padding(8)
                                .background(.ultraThinMaterial, in: Capsule())
                                .shadow(radius: 6)
                            }
                            .position(mid)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - グラフ生成：角を重ねた正方リング×2
private func makeOverlappedSquareGraph(side s: Int) -> [BoardNode] {
    precondition(s >= 2)
    let per = s - 1

    func ringCoords(side s: Int) -> [I2] {
        var coords: [I2] = []
        // 上辺 左->右（右上角はここでは含めない）
        for i in 0..<per { coords.append(I2(x: i, y: 0)) }
        // 右辺 上->下（右上角を含む）
        for i in 0..<per { coords.append(I2(x: per, y: i)) }
        // 下辺 右->左（右下角を含む）
        for i in 0..<per { coords.append(I2(x: per - i, y: per)) }
        // 左辺 下->上（左下角を含む／左上角は含めない）
        for i in 0..<per { coords.append(I2(x: 0, y: per - i)) }
        return coords
    }

    // 下側スクエア（基準）
    let base = ringCoords(side: s)
    // 上側スクエアを ( +per, -per ) 平行移動して重ねる
    let upper = base.map { I2(x: $0.x + per, y: $0.y - per) }

    // 同一座標は同一ノードにマージ
    var idForCoord: [I2: Int] = [:]
    var nodes: [BoardNode] = []

    func ensureNode(_ g: I2) -> Int {
        if let id = idForCoord[g] { return id }
        let id = nodes.count
        idForCoord[g] = id
        nodes.append(BoardNode(id: id, grid: g, neighbors: []))
        return id
    }

    func addRing(_ coords: [I2]) {
        guard !coords.isEmpty else { return }
        let ids = coords.map { ensureNode($0) }
        for i in 0..<ids.count {
            let a = ids[i]
            let b = ids[(i + 1) % ids.count] // 環状
            if !nodes[a].neighbors.contains(b) { nodes[a].neighbors.append(b) }
            if !nodes[b].neighbors.contains(a) { nodes[b].neighbors.append(a) }
        }
    }

    addRing(base)
    addRing(upper)
    return nodes
}

// MARK: - 描画ユーティリティ
private func bounds(_ pts: [I2]) -> (Int, Int, Int, Int) {
    let xs = pts.map { $0.x }
    let ys = pts.map { $0.y }
    return (xs.min() ?? 0, xs.max() ?? 0, ys.min() ?? 0, ys.max() ?? 0)
}

private func point(for g: I2, minX: Int, minY: Int, step: CGFloat, origin: CGPoint, tileSize: CGFloat) -> CGPoint {
    let x = CGFloat(g.x - minX) * step + origin.x + tileSize / 2
    let y = CGFloat(g.y - minY) * step + origin.y + tileSize / 2
    return CGPoint(x: x, y: y)
}

private func angle(from a: CGPoint, to b: CGPoint) -> Angle {
    Angle(radians: atan2(b.y - a.y, b.x - a.x))
}

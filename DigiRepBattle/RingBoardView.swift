//
//  RingBoardView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

enum TileAttribute: String {
    case normal, dry, water, heat, cold
}

private enum TileCorner { case topLeft, topRight }

struct TileTerrain {
    let imageName: String      // 例: "field", "desert", "water", "fire", "snow", "town"
    let attribute: TileAttribute
}

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
    let highlightTargets: Set<Int>

    // 分岐UI（既存そのまま）
    var branchSource: Int? = nil
    var branchCandidates: [Int] = []
    var onPickBranch: ((Int) -> Void)? = nil
    var onTapTile: ((Int) -> Void)? = nil
    var focusTile: Int? = nil

    // ★ 追加：パン・ズーム状態
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var gestureScale: CGFloat = 1.0
    @State private var gestureOffset: CGSize = .zero
    @State private var terrains: [TileTerrain] = []
    @State private var p1HopFlag = false
    @State private var p2HopFlag = false
    @State private var autoFollowCamera = true

    // 角を重ねた正方形×2 のグラフ
    private var graph: [BoardNode] {
        makeOverlappedSquareGraph(side: sideCount)
    }

    var body: some View {
        GeometryReader { geo in
            let step = tileSize + gap
            let count = graph.count

            // グリッド境界→盤の自然サイズ（原点はこのビューの左上）
            let (minX, maxX, minY, maxY) = bounds(graph.map { $0.grid })
            let spanX = CGFloat(maxX - minX)
            let spanY = CGFloat(maxY - minY)
            let boardSize   = CGSize(width: (spanX + 1) * step,
                                     height: (spanY + 1) * step)
            let boardCenter = CGPoint(x: boardSize.width / 2,
                                      y: boardSize.height / 2)
            // 既存の“中央配置”はやめ、原点(0,0) から描画。
            // 中央寄せは offset/scale で行う（=カメラ方式）。
            ZStack {
                // エッジ
                Path { p in
                    for node in graph {
                        let a = node.id
                        let aPos = pointNoOrigin(for: node.grid, minX: minX, minY: minY, step: step, tileSize: tileSize)
                        for b in node.neighbors where b > a {
                            let bPos = pointNoOrigin(for: graph[b].grid, minX: minX, minY: minY, step: step, tileSize: tileSize)
                            p.move(to: aPos)
                            p.addLine(to: bPos)
                        }
                    }
                }
                .stroke(.secondary.opacity(0.35), lineWidth: 2)

                // タイル
                ForEach(graph) { node in
                    let idx = node.id
                    let pos = pointNoOrigin(for: node.grid, minX: minX, minY: minY, step: step, tileSize: tileSize)

                    let safeOwner   = owner.indices.contains(idx) ? owner[idx] : nil
                    let safeLevel   = level.indices.contains(idx) ? level[idx] : 0
                    let safeSymbol  = creatureSymbol.indices.contains(idx) ? creatureSymbol[idx] : nil
                    let safeHp      = hp.indices.contains(idx) ? hp[idx] : nil
                    let safeHpMax   = hpMax.indices.contains(idx) ? hpMax[idx] : nil
                    let safeToll    = (idx < owner.count) ? toll(idx) : 0
                    let terr = terrains.indices.contains(idx) ? terrains[idx] : TileTerrain(imageName: "field", attribute: .normal)

                    TileView(index: idx,
                             size: tileSize,
                             hasP1: idx == p1Pos,
                             hasP2: idx == p2Pos,
                             owner: safeOwner,
                             level: safeLevel,
                             creatureSymbol: safeSymbol,
                             toll: safeToll,
                             hp: safeHp,
                             hpMax: safeHpMax,
                             bgImageName: terr.imageName,
                             attribute: terr.attribute,
                             highlightTargets: highlightTargets
                    )
                    .position(pos)
                    .onTapGesture {
                        onTapTile?(idx) 
                    }
                }
                
                let inset = tileSize * 0.18
                // === P1 / P2 トークン（タイルとは独立に位置アニメ）
                let p1CornerPoint = tileCornerPosition(
                    for: graph[p1Pos].grid,
                    minX: minX, minY: minY,
                    step: step, tileSize: tileSize,
                    corner: .topLeft,   // プレイヤーは左上
                    inset: inset
                )
                let p2CornerPoint = tileCornerPosition(
                    for: graph[p2Pos].grid,
                    minX: minX, minY: minY,
                    step: step, tileSize: tileSize,
                    corner: .topRight,  // CPUは右上
                    inset: inset
                )
                TokenView(systemName: "person.fill", color: .blue, hopFlag: $p1HopFlag)
                    .position(p1CornerPoint)
                    .animation(.interpolatingSpring(stiffness: 400, damping: 28), value: p1Pos)

                TokenView(systemName: "person.fill", color: .red, hopFlag: $p2HopFlag)
                    .position(p2CornerPoint)
                    .animation(.interpolatingSpring(stiffness: 400, damping: 28), value: p2Pos)

                // 分岐選択UI（既存そのまま）
                if let src = branchSource,
                   let srcNode = graph.first(where: { $0.id == src }),
                   !branchCandidates.isEmpty {
                    let srcPos = pointNoOrigin(for: srcNode.grid, minX: minX, minY: minY, step: step, tileSize: tileSize)
                    ForEach(branchCandidates, id: \.self) { cand in
                        let targetPos = pointNoOrigin(for: graph[cand].grid, minX: minX, minY: minY, step: step, tileSize: tileSize)
                        let mid = CGPoint(x: (srcPos.x + targetPos.x) / 2, y: (srcPos.y + targetPos.y) / 2)
                        Button { onPickBranch?(cand) } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "arrowtriangle.forward.fill")
                                    .rotationEffect(angle(from: srcPos, to: targetPos))
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .padding(8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .shadow(radius: 6)
                        }
                        .position(mid)
                    }
                }
            }
            .onChange(of: p1Pos) { _, _ in p1HopFlag.toggle() }
            .onChange(of: p2Pos) { _, _ in p2HopFlag.toggle() }
            .frame(width: boardSize.width, height: boardSize.height, alignment: .topLeading)
            // ★ ここで“疑似カメラ”を適用
            .scaleEffect(scale * gestureScale, anchor: .center)
            .offset(x: offset.width + gestureOffset.width,
                    y: offset.height + gestureOffset.height)
            .contentShape(Rectangle()) // ヒット領域
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        autoFollowCamera = false                      // ← 追従停止
                        // 既存の拡大処理
                        let newS = min(max(scale * value, 0.6), 2.5)
                        let pivot = boardPointAtScreenCenter(viewSize: geo.size, boardCenter: boardCenter, s: scale)
                        let newOffset = offsetForCentering(point: pivot, viewSize: geo.size, boardCenter: boardCenter, s: newS)
                        gestureScale = value
                        gestureOffset = CGSize(width: newOffset.width - offset.width, height: newOffset.height - offset.height)
                    }
                    .onEnded { value in
                        let newS = min(max(scale * value, 0.6), 2.5)
                        let pivot = boardPointAtScreenCenter(viewSize: geo.size, boardCenter: boardCenter, s: scale)
                        let newOffset = offsetForCentering(point: pivot, viewSize: geo.size, boardCenter: boardCenter, s: newS)
                        withAnimation(.easeInOut(duration: 0.15)) {
                            scale = newS
                            offset = newOffset
                            gestureScale = 1.0
                            gestureOffset = .zero
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { autoFollowCamera = true } // ← 再開
                    }
            )

            // ★ ドラッグ（平行移動）
            .simultaneousGesture(
                DragGesture()
                    .onChanged { v in gestureOffset = v.translation }
                    .onEnded { v in
                        offset.width += v.translation.width
                        offset.height += v.translation.height
                        gestureOffset = .zero
                    }
            )
            .onAppear {
                if terrains.count != count {
                    terrains = buildFixedTerrains(count: count)
                }
            }
            // 初回レイアウト時に、現在プレイヤーの位置へ
            .onAppear {
                if let idx = focusTile {
                    centerOnTile(idx,
                                 in: geo.size,
                                 boardCenter: boardCenter,
                                 minX: minX, minY: minY,
                                 step: step, tileSize: tileSize,
                                 animated: false)
                }
            }
            .onChange(of: focusTile) { _, new in
                guard let idx = new, autoFollowCamera else { return }
                DispatchQueue.main.async {
                    centerOnTile(idx,
                                 in: geo.size,
                                 boardCenter: boardCenter,
                                 minX: minX, minY: minY,
                                 step: step, tileSize: tileSize)
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        autoFollowCamera = false
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            autoFollowCamera = true
                        }
                    }
            )
        }
    }

    // === 中央寄せ（疑似カメラ）：盤座標→画面中央へくるよう offset を決める ===
    private func centerOnTile(_ idx: Int,
                              in viewSize: CGSize,
                              boardCenter: CGPoint,
                              minX: Int, minY: Int,
                              step: CGFloat, tileSize: CGFloat,
                              animated: Bool = true)
    {
        // タイル中心（盤のローカル座標・(0,0)起点）
        let p = pointNoOrigin(for: graph[idx].grid, minX: minX, minY: minY, step: step, tileSize: tileSize)
        let viewCenter = CGPoint(x: viewSize.width/2, y: viewSize.height/2)

        // “今の（確定済み）スケール”を使ってオフセットを計算（ジェスチャー中でない前提）
        let s = scale

        // centerアンカーの変換:
        // screen = (p - boardCenter)*s + boardCenter + offset
        // → offset = viewCenter - [(p - boardCenter)*s + boardCenter]
        let target = CGSize(
            width:  viewCenter.x - ((p.x - boardCenter.x) * s + boardCenter.x),
            height: viewCenter.y - ((p.y - boardCenter.y) * s + boardCenter.y)
        )

        // ついでに、ちょっと寄りのズーム（任意）：見やすい倍率に穏やかに調整
        let targetScale = (s < 1.2) ? 1.2 : min(s, 2.0)

        let apply = {
            self.scale = targetScale
            self.offset = target
            self.gestureScale = 1.0
            self.gestureOffset = .zero
        }

        if animated {
            withAnimation(.easeInOut(duration: 0.35)) { apply() }
        } else {
            apply()
        }
    }

    // 旧 `point(for:)` と同等だが、中央寄せoriginを使わない版（左上原点）
    private func pointNoOrigin(for g: I2, minX: Int, minY: Int, step: CGFloat, tileSize: CGFloat) -> CGPoint {
        let x = CGFloat(g.x - minX) * step + tileSize / 2
        let y = CGFloat(g.y - minY) * step + tileSize / 2
        return CGPoint(x: x, y: y)
    }
    
    // 画面中央にある盤上の点（board座標）を、現在の scale と offset から逆算
    private func boardPointAtScreenCenter(viewSize: CGSize,
                                          boardCenter: CGPoint,
                                          s: CGFloat) -> CGPoint {
        let vc = CGPoint(x: viewSize.width/2, y: viewSize.height/2)
        // centerアンカーの順変換: screen = (p - boardCenter)*s + boardCenter + offset
        // 逆算: p = ((screen - offset - boardCenter) / s) + boardCenter
        return CGPoint(
            x: ((vc.x - offset.width  - boardCenter.x) / s) + boardCenter.x,
            y: ((vc.y - offset.height - boardCenter.y) / s) + boardCenter.y
        )
    }

    // 指定した盤上点 p を画面中央に置くための offset を計算
    private func offsetForCentering(point p: CGPoint,
                                    viewSize: CGSize,
                                    boardCenter: CGPoint,
                                    s: CGFloat) -> CGSize {
        let vc = CGPoint(x: viewSize.width/2, y: viewSize.height/2)
        // offset = viewCenter - [(p - boardCenter)*s + boardCenter]
        return CGSize(
            width:  vc.x - ((p.x - boardCenter.x) * s + boardCenter.x),
            height: vc.y - ((p.y - boardCenter.y) * s + boardCenter.y)
        )
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
private func generateTerrains(count: Int) -> [TileTerrain] {
    var t = Array(repeating: TileTerrain(imageName: "field", attribute: .normal), count: count)

    // 固定マス（1,5,21）= index 0,4,20
    let fixed = [0, 4, 20].filter { $0 < count }
    for i in fixed {
        t[i] = TileTerrain(imageName: "town", attribute: .normal)
    }

    let candidates: [(String, TileAttribute)] = [
        ("field", .normal),
        ("desert", .dry),
        ("water", .water),
        ("fire",  .heat),
        ("snow",  .cold),
    ]

    for i in 0..<count where !fixed.contains(i) {
        if let pick = candidates.randomElement() {
            t[i] = TileTerrain(imageName: pick.0, attribute: pick.1)
        }
    }
    return t
}

private func buildFixedTerrains(count: Int) -> [TileTerrain] {
    var t = Array(repeating: TileTerrain(imageName: "field", attribute: .normal), count: count)

    // 1始まりの範囲を0始まりindexに適用するヘルパ
    func setRange(_ startTile: Int, _ endTile: Int, _ image: String, _ attr: TileAttribute) {
        let s = max(1, startTile)
        let e = min(count, endTile)
        guard s <= e else { return }
        for tile in s...e {
            t[tile - 1] = TileTerrain(imageName: image, attribute: attr)
        }
    }

    // 指定：
    setRange(1,1,"town",.normal)
    // マス2〜4: field
    setRange(2, 4, "field", .normal)
    setRange(5,5,"town",.normal)
    // マス6〜9: desert
    setRange(6, 9, "desert", .dry)
    // マス10〜13: water
    setRange(10, 13, "water", .water)
    // マス14〜16: field
    setRange(14, 16, "field", .normal)
    // マス17〜20: fire
    setRange(17, 20, "fire", .heat)
    setRange(21,21,"town",.normal)
    // マス22〜25: snow
    setRange(22, 25, "snow", .cold)
    // マス26〜31: field
    setRange(26, 31, "field", .normal)

    return t
}

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

// === 駒（跳ねアニメ付き）の小さなView
private struct TokenView: View {
    let systemName: String
    let color: Color
    @Binding var hopFlag: Bool

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(color)
            .padding(6)
            .background(.thinMaterial, in: Circle())
            // hopFlag が変わるたびに 0→1→0 の値を走らせる
            .keyframeAnimator(initialValue: CGFloat(0), trigger: hopFlag) { content, v in
                content
                    .offset(y: -30 * v)        // 上に持ち上げる
                    .scaleEffect(1 + 0.08 * v) // ほんの少し拡大
            } keyframes: { _ in
                KeyframeTrack(\.self) {
                    // ひゅっと上がる（0 → 1）
                    CubicKeyframe(1.0, duration: 0.12)
                    // すっと戻る（1 → 0）スプリング
                    SpringKeyframe(0.0, duration: 0.22, spring: .init(response: 0.22, dampingRatio: 0.9))
                }
            }
    }
}


private func tileCornerPosition(
    for grid: I2,
    minX: Int, minY: Int,
    step: CGFloat, tileSize: CGFloat,
    corner: TileCorner,
    inset: CGFloat
) -> CGPoint {
    let cx = CGFloat(grid.x - minX) * step + tileSize / 2
    let cy = CGFloat(grid.y - minY) * step + tileSize / 2

    switch corner {
    case .topLeft:
        return CGPoint(x: cx - tileSize/2 + inset,
                       y: cy - tileSize/2 + inset)
    case .topRight:
        return CGPoint(x: cx + tileSize/2 - inset,
                       y: cy - tileSize/2 + inset)
    }
}


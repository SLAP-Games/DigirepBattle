//
//  ContentView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = GameVM()

    var body: some View {
        GeometryReader { geo in
            let controlRatio: CGFloat = 0.25
            let controlsH = geo.size.height * controlRatio
            let boardH = geo.size.height - controlsH

            VStack(spacing: 0) {
                // ── 上：ボードエリア ──
                ZStack(alignment: .center) {
                    RingBoardView(
                        p1Pos: vm.players[0].pos,
                        p2Pos: vm.players[1].pos,
                        owner: vm.owner,
                        level: vm.level,
                        creatureSymbol: vm.creatureSymbol,
                        toll: vm.toll,
                        hp: vm.hp,
                        hpMax: vm.hpMax,
                        highlightTargets: vm.branchLandingTargets,
                        branchSource: vm.branchSource,
                        branchCandidates: vm.branchCandidates,
                        onPickBranch: { vm.pickBranch($0) },
                        onTapTile: { idx in
                            if vm.isForcedSaleMode && vm.turn == 0 {
                                vm.requestSell(tile: idx)        // 自軍タイルなら売却ポップへ（ガードは中で実施）
                            } else {
                                vm.tapTileForInspect(idx)        // 既存動作：インスペクト
                            }
                        },
                        focusTile: vm.focusTile
                    )
                    .frame(height: boardH)
                    .background {
                        Image("backGround1")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }
                    .overlay(
                        VStack(alignment: .trailing, spacing: 6) {
                            // CPスター（CP1・CP2）
                            HStack(spacing: 6) {
                                let cp1CPU = vm.passedCP1.indices.contains(1) && vm.passedCP1[1]
                                let cp2CPU = vm.passedCP2.indices.contains(1) && vm.passedCP2[1]

                                Image(systemName: cp1CPU ? "star.fill" : "star")
                                    .foregroundStyle(cp1CPU ? .yellow : .gray)
                                Image(systemName: cp2CPU ? "star.fill" : "star")
                                    .foregroundStyle(cp2CPU ? .yellow : .gray)
                            }
                            .font(.caption) // 大きさはお好みで
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            // CPUバッジ
                            Badge(player: vm.players[1],
                                  active: vm.turn == 1,
                                  tint: .red,
                                  total: vm.totalAssets(for: 1)
                            )
                        }
                        .padding(.bottom, 10)
                        .padding(.trailing, 12)
                        .allowsHitTesting(false),            // 盤面タップの邪魔をしない
                        alignment: .bottomTrailing
                    )

                    // ★ ここで貼る：プレイヤーバッジ（左下）
                    .overlay(
                        VStack(alignment: .trailing, spacing: 6) {
                            // CPスター（CP1・CP2）
                            HStack(spacing: 6) {
                                let cp1Player = vm.passedCP1.indices.contains(0) && vm.passedCP1[0]
                                let cp2Player = vm.passedCP2.indices.contains(0) && vm.passedCP2[0]

                                Image(systemName: cp1Player ? "star.fill" : "star")
                                    .foregroundStyle(cp1Player ? .yellow : .gray)
                                Image(systemName: cp2Player ? "star.fill" : "star")
                                    .foregroundStyle(cp2Player ? .yellow : .gray)
                            }
                            .font(.caption) // 大きさはお好みで
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Badge(player: vm.players[0],
                                  active: vm.turn == 0,
                                  tint: .blue,
                                  total: vm.totalAssets(for: 0)
                            )
                        }
                        .padding(.bottom, 10)
                        .padding(.leading, 12)
                        .allowsHitTesting(false),
                        alignment: .bottomLeading
                    )
                    
                    .overlay(alignment: .center) {
                        if let card = vm.presentingCard {
                            CardDetailOverlay(
                                card: card,
                                vm: vm,
                                onClose: { vm.closeCardPopup() }
                            )
                            .fixedSize(horizontal: false, vertical: true) // 中身サイズだけにする
                            .padding(12)                                  // ボード枠からの余白
                            .transition(.opacity.combined(with: .scale))
                            .zIndex(900)
                        }
                    }
                    
                    if vm.showCheckpointOverlay {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text(vm.checkpointMessage ?? "チェックポイント通過")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                Button("閉じる") {
                                    vm.closeCheckpointOverlay()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(radius: 8)
                            )
                            .padding()
                        }
                        .transition(.opacity)
                        .zIndex(999) // 最前面に
                    }
                    
                    if let idx = vm.inspectTarget,
                       let iv = vm.makeInspectView(for: idx, viewer: 0) { // 0 = You
                        CreatureInfoPanel(iv: iv, onClose: { vm.closeInspect() })
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .zIndex(10)
                    }
                    
                    if let sheet = vm.activeSpecialSheet {
                        // 半透明の背面
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture {
                                vm.activeSpecialSheet = nil
                            } // 背面タップで閉じる

                        // 中央カード
                        Group {
                            switch sheet {
                            case .levelUp(let tile):
                                PopupCard {
                                    LevelUpSheetView(vm: vm, tile: tile)
                                }
                            case .moveFrom(let tile):
                                PopupCard {
                                    MoveCreatureSheetView(vm: vm, fromTile: tile)
                                }
                            case .buySpell:
                                PopupCard {
                                    PurchaseSpellSheetView(vm: vm)
                                }
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: vm.activeSpecialSheet)
                    }
                    
                    if let t = vm.sellConfirmTile {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                let before = vm.players[0].gold
                                let add    = vm.saleValue(for: t)
                                let after  = vm.sellPreviewAfterGold   // = before + add

                                Text("売却しますか？").font(.headline)
                                Text("-\(max(0, -before)) GOLD → \(after) GOLD").font(.subheadline)

                                HStack {
                                    Button("キャンセル") { vm.cancelSellTile() }
                                    Spacer().frame(width: 12)
                                    Button("OK") { vm.confirmSellTile() }.bold()
                                }
                                .padding(.top, 8)
                            }
                            .padding(16)
                            .frame(maxWidth: 300)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: vm.sellConfirmTile != nil)
                    }
                    
                    if let idx = vm.pendingSwapHandIndex,
                       vm.hands.indices.contains(0),
                        vm.hands[0].indices.contains(idx) {

                        let price = vm.hands[0][idx].stats?.cost ?? 0
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text("交換しますか？")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                Text("必要コスト \(price) GOLD")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Button("交換") {
                                        vm.confirmSwapPending()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!vm.canSwapCreature(withHandIndex: idx))

                                    Button("キャンセル") {
                                        vm.cancelSwapPending()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(radius: 8)
                            )
                            .padding()
                        }
                        .transition(.opacity)
                        .zIndex(998)
                    }

                }

                // ── 下：操作エリア（自プレイヤー専用） ──
                ZStack(alignment: .center) {
                    Image("underMenuBackground")
                        .resizable()
                        .scaledToFill()
                        .allowsHitTesting(false)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Button("🎲 Roll") { vm.rollDice() }
                                .disabled(!(vm.turn == 0 && vm.phase == .ready && vm.mustDiscardFor == nil))
                            
                            Button("✅ End") { vm.endTurn() }
                                .disabled(!(vm.turn == 0 && vm.phase == .moved))
                                .disabled(!vm.canEndTurn)
                            
                            Text("Roll: \(vm.lastRoll)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderedProminent)
                        .overlay {
                            if vm.mustDiscardFor == 0 {
                                ZStack {
                                    Color.black.opacity(0.6)
                                    Text("手札を\n捨てて\nください")
                                        .foregroundColor(.white)
                                }
                                .allowsHitTesting(false)
                            }
                        }

                        Divider().frame(height: controlsH * 0.8)

                        // 右：手札（横並び）— 状況に応じて使用可否
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vm.hands[0]) { card in
                                    CardView(card: card)
                                        .onTapGesture { vm.openCard(card)
                                        }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: controlsH * 0.9)
                            
                    }
                    .padding(.horizontal)
                    
                    if let card = vm.presentingCard,
                       card.kind == .creature,
                       vm.turn == 0,
                       vm.mustDiscardFor == nil {

                        // 現在タイルの状況を判定
                        let t = vm.players[0].pos
                        let isMy = vm.owner.indices.contains(t) && vm.owner[t] == 0
                        let isCPU = vm.owner.indices.contains(t) && vm.owner[t] == 1
                        let hasCreature = vm.creatureSymbol.indices.contains(t) && vm.creatureSymbol[t] != nil
                        let canPlace = (vm.owner.indices.contains(t) && vm.owner[t] == nil) && vm.canPlaceCreature(at: t)

                        // 1) 空き地（未占領） → 配置するか？
                        if canPlace {
                            ZStack {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .allowsHitTesting(false)
                                VStack {
                                    Text("このデジレプを配置しますか？")
                                        .font(.subheadline).bold()
                                    
                                    HStack(spacing: 12) {
                                        Button("配置") {
                                            // 現在地に配置してカード消費
                                            vm.confirmPlaceCreatureFromHand(card, at: t, by: 0)
                                            vm.closeCardPopup()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        
                                        Button("キャンセル") {
                                            vm.closeCardPopup()
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        // 2) 自分のデジレプが設置済み
                        else if isMy && hasCreature {
                            if vm.phase == .ready {
                                // 移動前：占領済み（配置不可）
                                ZStack {
                                    Image("underMenuBackgroundRed")
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                        .allowsHitTesting(false)
                                    VStack(spacing: 12) {
                                        Text("占領済みです")
                                            .font(.subheadline).bold()
                                        Button("キャンセル") {
                                            vm.closeCardPopup()
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else if vm.phase == .moved {
                                // 移動後：CreatureMenuView を表示する
                                ZStack {
                                    Image("underMenuBackgroundRed")
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                        .allowsHitTesting(false)
                                    CreatureMenuView(
                                        vm: vm,
                                        tile: t,
                                        selectedCard: card,
                                        onClose: {
                                            vm.showCreatureMenu = false
                                            vm.creatureMenuTile = nil
                                            vm.closeCardPopup()
                                        }
                                    )
                                    .frame(height: controlsH)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                                .onAppear {
                                    vm.creatureMenuTile = t
                                    vm.showCreatureMenu = true
                                }
                            }
                        }
                        // 3) CPUのデジレプが設置済み
                        else if isCPU && hasCreature {
                            // CPU領地（配置不可）
                            ZStack {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .allowsHitTesting(false)
                                VStack(spacing: 12) {
                                    Text("相手の領地です")
                                        .font(.subheadline).bold()
                                    Button("キャンセル") {
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        // フォールバック（想定外状況）
                        else {
                            ZStack {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .allowsHitTesting(false)
                                VStack(spacing: 12) {
                                    Text("この場所では配置できません")
                                        .font(.subheadline).bold()
                                    Button("キャンセル") {
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.bordered)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    
                    if let t = vm.landedOnOpponentTileIndex,
                       vm.turn == 0, vm.phase == .moved, !vm.expectBattleCardSelection {
                        ZStack{
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .allowsHitTesting(false)
                            VStack {
                                Text("相手の領地です。").bold()

                                HStack(spacing: 12) {
                                    Button("戦闘する") { vm.chooseBattle() }
                                        .buttonStyle(.borderedProminent)
                                    Button("通行料を払う") { vm.payTollAndEndChoice() }
                                        .buttonStyle(.bordered)
                                }
                                .padding(8)
                            }
                        }
                    }
                    
                    if vm.showSpecialMenu {
                        ZStack{
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .allowsHitTesting(false)
                            SpecialNodeMenu(
                                kind: vm.currentSpecialKind,
                                levelUp: { vm.actionLevelUpOnSpecialNode() },
                                moveCreature: { vm.actionMoveCreatureFromSpecialNode() },
                                buySkill: { vm.actionPurchaseSkillOnSpecialNode() },
                                endTurn: {
                                    vm.endTurn()
                                }
                            )
                            .frame(height: controlsH)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

                    if let text = vm.battleResult {
                        ZStack {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .allowsHitTesting(false)

                            VStack(spacing: 12) {
                                Text(text)
                                    .multilineTextAlignment(.center)
                                    .font(.title3.bold())
                                    .padding(.vertical, 4)

                                Button("閉じる") { vm.battleResult = nil }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(radius: 10)
                        }
                    }
                    
                    if let card = vm.presentingCard,
                       card.kind == .spell,
                       vm.turn == 0, (vm.phase == .ready || vm.phase == .moved), vm.mustDiscardFor == nil,
                       isFixNextRollSpell(card) {

                        ZStack {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .allowsHitTesting(false)
                            VStack {
                                Text("スペル使用先を選択")
                                    .font(.subheadline).bold()
                                
                                HStack(spacing: 12) {
                                    Button("自分") {
                                        vm.useSpellPreRoll(card, target: 0)
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("CPU") {
                                        vm.useSpellPreRoll(card, target: 1)
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("キャンセル") {
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if vm.isForcedSaleMode && vm.turn == 0 {
                        ZStack {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .allowsHitTesting(false)
                            Text("売却する土地を選んでください\n現在のマイナス \(vm.debtAmount) GOLD")
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    VStack {
                        Image("line")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                        Spacer()
                    }
                }
                .frame(height: controlsH)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(Divider(), alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    private func isFixNextRollSpell(_ card: Card) -> Bool {
        guard card.kind == .spell, let e = card.spell else { return false }
        if case .fixNextRoll(let n) = e { return (1...6).contains(n) }
        return false
    }
}

private struct Badge: View {
    let player: Player
    let active: Bool
    let tint: Color
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name).bold()
                Text("Gold: \(player.gold)")
                    .font(.caption)
                Text("TOTAL: \(total)")
                    .font(.caption)
            }
        }
        .padding(8)
        .background(active ? .yellow.opacity(0.8) : .white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CardView: View {
    let card: Card
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .overlay(
                    Image("cardS")
                        .resizable()
                        .scaledToFill()
                )
                .frame(width: 90, height: 130)

            VStack(spacing: 6) {
                Text(card.kind == .spell ? "スペル" : "デジレプ")
                    .font(.caption2)
                    .foregroundStyle(.white)
                Image(card.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            }
            .padding(6)
        }
    }
}

struct CreatureMenuView: View {
    @ObservedObject var vm: GameVM
    let tile: Int
    let selectedCard: Card     // ← 追加：選択中の“カードA”
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // ヘッダー
            HStack {
                Text("自軍領地メニュー").font(.headline)
                Spacer()
                Button("閉じる", action: onClose).buttonStyle(.bordered)
            }

            // メニュー（レベルアップ / 即時交換）
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // レベルアップ（既存のまま）
                    if vm.level.indices.contains(tile),
                       vm.level[tile] >= 1, vm.level[tile] < 5 {
                        let nextLv = vm.level[tile] + 1
                        let need   = vm.levelUpCost[nextLv] ?? 0
                        Button {
                            vm.confirmLevelUp(tile: tile, to: nextLv)
                        } label: {
                            VStack(spacing: 4) {
                                Text("レベルアップ").bold()
                                Text("→ Lv.\(nextLv)（\(need)G）")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(vm.players[vm.turn].gold < need)
                        .buttonStyle(.borderedProminent)
                    }

                    // ★ 即時交換（選択カードAのコストを表示）
                    let cost = selectedCard.stats?.cost ?? 0
                    Button {
                        vm.requestImmediateSwap(forSelectedCard: selectedCard)
                    } label: {
                        VStack(spacing: 4) {
                            Text("デジレプ交換").bold()
                            Text("\(cost)G")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!vm.canSwapCreature(withHandIndex:
                        (vm.hands[vm.turn].firstIndex(of: selectedCard) ?? -1)
                    ))
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SpecialNodeMenu: View {
    let kind: SpecialNodeKind?
    let levelUp: () -> Void
    let moveCreature: () -> Void
    let buySkill: () -> Void
    let endTurn: () -> Void

    var title: String {
        switch kind {
        case .some(.castle): return "城"
        case .some(.tower):  return "塔"
        case .none:          return "特別マス"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(spacing: 12) {
                Button("領地強化", action: levelUp)
                    .buttonStyle(.borderedProminent)

                Button("デジレプ転送", action: moveCreature)
                    .buttonStyle(.bordered)

                Button("スキル購入", action: buySkill)
                    .buttonStyle(.bordered)

                Button("ターン終了", action: endTurn)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// 角度で正面/背面の描画を自動切替しつつ回転させる版
struct FlipAngle<Front: View, Back: View>: View, Animatable {
    // ← Animatable 準拠を追加
    var angle: Double
    var perspective: CGFloat = 0.6
    let front: () -> Front
    let back: () -> Back

    // これを追加：angle をアニメーションのドライバにする
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    init(angle: Double,
         perspective: CGFloat = 0.6,
         @ViewBuilder front: @escaping () -> Front,
         @ViewBuilder back: @escaping () -> Back) {
        self.angle = angle
        self.perspective = perspective
        self.front = front
        self.back = back
    }

    var body: some View {
        // 角度正規化（0...360）
        let a = angle.truncatingRemainder(dividingBy: 360)
        let norm = a < 0 ? a + 360 : a
        let showFront = !(90.0...270.0).contains(norm)

        return ZStack {
            front()
                .opacity(showFront ? 1 : 0)
                .zIndex(showFront ? 1 : 0)

            back()
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showFront ? 0 : 1)
                .zIndex(showFront ? 0 : 1)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: perspective)
        // （必要なら）透過ブレンドのチラつき対策
        .drawingGroup() // 任意
    }
}

// =======================
// 1) Flip 汎用ビュー
// =======================
struct Flip<Front: View, Back: View>: View {
    var isFront: Bool
    @State private var canShowFrontView: Bool
    let duration: Double
    let front: () -> Front
    let back: () -> Back

    init(isFront: Bool,
         duration: Double = 1.0,
         @ViewBuilder front: @escaping () -> Front,
         @ViewBuilder back: @escaping () -> Back) {
        self.isFront = isFront
        self._canShowFrontView = State(initialValue: isFront)
        self.duration = duration
        self.front = front
        self.back = back
    }

    var body: some View {
        ZStack {
            if canShowFrontView {
                front()
            } else {
                back()
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .onChange(of: isFront) { oldValue, newValue in
            // 半分回転したタイミングで front/back を入れ替える
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2.0) {
                self.canShowFrontView = newValue
            }
        }
        .animation(nil, value: canShowFrontView)
        .rotation3DEffect(isFront ? .degrees(0) : .degrees(180),
                          axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: duration), value: isFront)
    }
}

// =======================
// 2) カード詳細オーバーレイ
// =======================
private struct CardDetailOverlay: View {
    let card: Card
    @ObservedObject var vm: GameVM
    let onClose: () -> Void

    @State private var appearOpacity: Double = 0
    @State private var appearOffsetY: CGFloat = 50
    @State private var spinAngle: Double = 0      // ← 追加（0→720 に回す）

    private let frameImageName = "cardL"
    private let backImageName  = "CardLreverse"

    private var primaryAction: (title: String, action: (() -> Void)?, enabled: Bool) {
        if vm.mustDiscardFor == 0 { return ("捨てる", {
            vm.discard(card, for: 0); onClose() }, true)
        }
        if vm.phase == .ready && card.kind == .spell {
            return ("スペル使用", { vm.useSpellPreRoll(card); onClose() }, vm.turn == 0)
        }
        if vm.turn == 0 && vm.phase == .moved {
            if vm.expectBattleCardSelection && card.kind == .creature {
                return ("戦闘する", { vm.startBattle(with: card); onClose() }, true)
            } else {
                return ("カードを使用", { vm.useCardAfterMove(card); onClose() }, true)
            }
        }
        return ("使用できません", nil, false) }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(card.name)
                .font(.system(size: 26, weight: .semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(.white)
                .frame(maxWidth: 430)
                .padding(.horizontal, 20)

            // 角度制御版
            flipCardAngle
                .frame(maxWidth: 430)
                .opacity(appearOpacity)
                .onAppear {
                    appearOpacity = 0
                    withAnimation(.easeOut(duration: 0.7)) { appearOpacity = 1 }

                    // 0 → 720° を 1.5秒で線形回転
                    spinAngle = 0
                    withAnimation(.linear(duration: 0.6)) {
                        spinAngle = 360
                    }
                }
                .onDisappear {
                    appearOpacity = 0
                    spinAngle = 0
                }

            // ボタン類（そのまま）
            HStack(spacing: 10) {
                Button(primaryAction.title) { primaryAction.action?() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!primaryAction.enabled)

                Button("閉じる") { onClose() }
                    .buttonStyle(.bordered)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(radius: 12)
                    )
            }
        }
        .padding(.horizontal, 20)
        .opacity(appearOpacity)
        .offset(y: appearOffsetY)  // ← 下から上へ
        .onAppear {
            // 初期値
            appearOpacity = 0
            appearOffsetY = 50

            withAnimation(.easeOut(duration: 0.6)) {
                appearOpacity = 1
                appearOffsetY = 0
            }

            spinAngle = 0
            withAnimation(.linear(duration: 0.7)) {
                spinAngle = 360
            }
        }
        .onDisappear {
            // リセット
            appearOpacity = 0
            appearOffsetY = 50
            spinAngle = 0
        }
    }

    // ここを Flip → FlipAngle に
    private var flipCardAngle: some View {
        FlipAngle(angle: spinAngle) {
            FrontCardFace(card: card, vm: vm, frameImageName: frameImageName)
        } back: {
            BackCardFace(frameImageName: backImageName)
        }
        // 任意：タップでさらに 360° 回したい場合の例
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.linear(duration: 0.75)) {
                spinAngle += 360
            }
        }
    }
}

// =======================
// 3) 既存の Front / Back
// =======================
private struct FrontCardFace: View {
    let card: Card
    @ObservedObject var vm: GameVM
    let frameImageName: String

    var body: some View {
        ZStack {
            Image(frameImageName)
                .resizable()
                .aspectRatio(3/4, contentMode: .fit)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let sidePad = w * 0.12
                let topPad  = h * 0.04
                let imgH    = h * 0.48
                let heartH  = h * 0.052
                let statsTopGap = h * 0.03

                VStack(spacing: 0) {
                    Spacer().frame(height: topPad)

                    Image(card.symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(height: imgH)
                        .padding(.horizontal, sidePad)

                    if let s = card.stats {
                        HeartRow(count: max(0, min(s.affection, 10)))
                            .frame(height: heartH)
                            .padding(.top, h * 0.05)
                            .padding(.bottom, h * 0.02)
                    } else {
                        Spacer().frame(height: heartH)
                    }

                    VStack(spacing: statsTopGap) {
                        if case .creature = card.kind, let s = card.stats {
                            StatGrid2x4(items: [
                                ("コスト", "\(s.cost)"),
                                ("HP", "\(s.hpMax)"),
                                ("戦闘力", "\(s.power)"),
                                ("耐久力", "\(s.durability)"),
                                ("乾耐性", "\(s.resistDry)"),
                                ("水耐性", "\(s.resistWater)"),
                                ("熱耐性", "\(s.resistHeat)"),
                                ("冷耐性", "\(s.resistCold)")
                            ])
                            .padding(.horizontal, sidePad)
                            .padding(.bottom, h * 0.06)
                        } else {
                            Spacer().frame(height: heartH / 2)
                            Text(vm.spellDescription(for: card))
                                .font(.system(size: min(w, h) * 0.07))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(2)
                                .padding(.horizontal, sidePad * 0.7)
                                .padding(.bottom, h * 0.06)
                        }
                    }
                }
                .frame(width: w, height: h, alignment: .top)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}

private struct BackCardFace: View {
    let frameImageName: String
    // 画像の周囲をカットする量（pt）
    private let trim: CGFloat = 6

    var body: some View {
        ZStack {
            Image(frameImageName)
                .resizable()
                .aspectRatio(3/4, contentMode: .fit)
                // 縁取りをトリミング（上下左右を等幅でカット）
                .mask(
                    Rectangle().inset(by: trim)
                )

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let topPad  = h * 0.04
                VStack(spacing: 0) {
                    Spacer().frame(height: topPad)
                    Spacer()
                }
                .frame(width: w, height: h, alignment: .top)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 下パネル：2列×4行のステータス
private struct StatGrid2x4: View {
    let items: [(String, String)] // 8個を想定

    var body: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .leading), count: 2)
        LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
            ForEach(0..<items.count, id: \.self) { i in
                HStack {
                    Text(items[i].0)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Text(items[i].1)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - ハート行（なつき度）
private struct HeartRow: View {
    let count: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .foregroundColor(.red)
                    .shadow(radius: 1)
            }
        }
    }
}

#Preview {
    ContentView()
}

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
//                    .clipped()
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
                    
                    if vm.isTurnTransition {
                        TurnTransitionOverlay()
                            .transition(.opacity)
                    }
                    
                    if vm.showBattleOverlay, let L = vm.battleLeft, let R = vm.battleRight {
                        BattleOverlayView(left: L, right: R, attribute: vm.battleAttr) { finalL, finalR in
                            vm.finishBattle(finalL: finalL, finalR: finalR)
                        }
                    }
                }

                // ── 下：操作エリア（自プレイヤー専用） ──
                ZStack(alignment: .center) {
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
                            .frame(maxWidth: .infinity)
                            .background {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
//                            .clipped()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        // 2) 自分のデジレプが設置済み
                        else if isMy && hasCreature {
                            if vm.phase == .ready {
                                // 移動前：占領済み（配置不可）
                                ZStack {
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
                                .frame(maxWidth: .infinity)
                                .background {
                                    Image("underMenuBackgroundRed")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                                .clipped()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else if vm.phase == .moved {
                                // 移動後：CreatureMenuView を表示する
                                ZStack {
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
                                .frame(maxWidth: .infinity)
                                .background {
                                    Image("underMenuBackgroundRed")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
//                                .clipped()
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
                            .frame(maxWidth: .infinity)
                            .background {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
//                            .clipped()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        // フォールバック（想定外状況）
                        else {
                            ZStack {
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
                            .frame(maxWidth: .infinity)
                            .background {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
//                            .clipped()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    
                    if let t = vm.landedOnOpponentTileIndex,
                       vm.turn == 0, vm.phase == .moved, !vm.expectBattleCardSelection {
                        ZStack{
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
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
//                        .clipped()
                    }
                    
                    if vm.showSpecialMenu {
                        ZStack{
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
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
//                        .clipped()
                    }

                    if let text = vm.battleResult {
                        ZStack {
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
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
//                        .clipped()
                    }
                    
                    if let card = vm.presentingCard,
                       card.kind == .spell,
                       vm.turn == 0, (vm.phase == .ready || vm.phase == .moved), vm.mustDiscardFor == nil,
                       isFixNextRollSpell(card) {

                        ZStack {
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
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
//                        .clipped()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if vm.isForcedSaleMode && vm.turn == 0 {
                        ZStack {
                            Text("売却する土地を選んでください\n現在のマイナス \(vm.debtAmount) GOLD")
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
//                        .clipped()
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
                .background {
                    Image("underMenuBackground")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
//                .clipped()
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

struct CardDetailOverlay: View {
    let card: Card
    @ObservedObject var vm: GameVM
    let onClose: () -> Void

    @State private var appearOpacity: Double = 0
    @State private var appearOffsetY: CGFloat = 50
    @State private var spinAngle: Double = 0      // ← 追加（0→720 に回す）

    private let frameImageName = "cardL"
    private let backImageName  = "cardLreverse"

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
        return ("使用できません", nil, false)
    }
    
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

#Preview {
    ContentView()
}

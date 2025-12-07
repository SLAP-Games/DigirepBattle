//
//  GameVM.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI
import Foundation
import Combine

struct CreatureInspectView {
    let tileIndex: Int
    let mapImageName: String
    let mapAttribute: String
    let tileLevel: Int
    let tileStatus: String
    let owner: Int
    let imageName: String
    let hpText: String
    let affection: String
    let power: String
    let durability: String
    let dryRes: String
    let waterRes: String
    let heatRes: String
    let coldRes: String
}

@MainActor
final class GameVM: ObservableObject {
    enum Phase { case ready, rolled, moving, branchSelecting, moved }
    enum Dir { case cw, ccw }
    enum SpecialPendingAction { case pickLevelUpSource, pickMoveSource }
    
    @Published var branchSource: Int? = nil
    @Published var branchCandidates: [Int] = []
    @Published var focusTile: Int? = nil
    @Published var owner: [Int?]
    @Published var level: [Int]
    @Published var creatureSymbol: [String?]
    @Published var hp: [Int]
    @Published var hpMax: [Int]
    @Published var aff: [Int]
    @Published var pow: [Int]
    @Published var dur: [Int]
    @Published var rDry: [Int]
    @Published var rWat: [Int]
    @Published var rHot: [Int]
    @Published var rCold: [Int]
    @Published var cost: [Int]
    @Published var showSpecialMenu: Bool = false
    @Published var currentSpecialKind: SpecialNodeKind? = nil
    @Published var toll: [Int]
    @Published var players: [Player] = [
        Player(name: "You", pos: 0, gold: 300),
        Player(name: "CPU", pos: 0, gold: 300)
    ]
    @Published var turn: Int = 0
    @Published var lastRoll: Int = 0
    @Published var phase: Phase = .ready
    @Published var mustDiscardFor: Int? = nil
    @Published var showLogOverlay: Bool = false
    @Published var canEndTurn: Bool = true
    @Published var terrain: [TileTerrain] = []
    @Published var inspectTarget: Int? = nil
    @Published var creatureOnTile: [Int: Creature] = [:]
    @Published var landedOnOpponentTileIndex: Int? = nil
    @Published var expectBattleCardSelection: Bool = false
    @Published var logs: [String] = []
    @Published var battleResult: String? = nil
    @Published var showCheckpointOverlay: Bool = false
    @Published var checkpointMessage: String? = nil
    @Published var lastCheckpointGain: Int = 0
    @Published var activeSpecialSheet: SpecialActionSheet? = nil
    @Published var specialPending: SpecialPendingAction? = nil
    @Published var presentingCard: Card? = nil
    @Published var shopSpellForDetail: ShopSpell? = nil
    @Published var passedCP1: [Bool] = [false, false]
    @Published var passedCP2: [Bool] = [false, false]
    @Published var showCreatureMenu: Bool = false
    @Published var creatureMenuTile: Int? = nil
    @Published var showMyTile = false
    @Published var myTileIndex: Int?
    @Published var isSelectingSwapCreature: Bool = false
    @Published var isForcedSaleMode: Bool = false
    @Published var debtAmount: Int = 0
    @Published var sellConfirmTile: Int? = nil
    @Published var sellPreviewAfterGold: Int = 0
    @Published var branchLandingTargets: Set<Int> = []
    @Published var pendingSwapHandIndex: Int? = nil
    @Published var isTurnTransition = false
    @Published var showBattleOverlay = false
    @Published var battleLeft: BattleCombatant?
    @Published var battleRight: BattleCombatant?
    @Published var battleAttr: BattleAttribute = .normal
    @Published var currentBattleTile: Int? = nil
    @Published var currentAttackingCard: Card? = nil
    @Published var isAwaitingBattleResult: Bool = false
    @Published var cardStates: [PlayerCardState] = [
        PlayerCardState(collection: CardCollection(), deckList: DeckList()),
        PlayerCardState(collection: CardCollection(), deckList: DeckList())
    ]
    @Published var doubleDice: [Bool] = [false, false]
    @Published var clairvoyanceRevealedCreatureIDs: [Set<String>] = [[], []]
    @Published var isBattleItemSelectionPhase: Bool = false
    @Published var isHealingAnimating: Bool = false
    @Published var healingAmounts: [Int: Int] = [:]
    @Published var poisonedTiles: [Bool]
    @Published var defenderHasFirstStrike: Bool = false
    @Published var drawPreviewCard: Card? = nil
    @Published var pendingDrawPreviewQueue: [Card] = []
    @Published var isSelectingOpponentHandToDelete: Bool = false
    @Published var deletingTargetPlayer: Int? = nil
    @Published var pendingDeleteHandIndex: Int? = nil
    @Published var deletePreviewCard: Card? = nil
    // === ここから追加: sp-elixir 用 ===
    @Published var isSelectingFullHealTarget: Bool = false
    @Published var fullHealCandidateTiles: Set<Int> = []
    @Published var pendingFullHealTile: Int? = nil
    // ★ SpellEffectScene 用：タイル上に出すエフェクト（回復／毒 など）
    @Published var spellEffectTile: Int? = nil
    @Published var spellEffectKind: SpellEffectScene.EffectKind = .heal
    @Published var plunderEffectTile: Int? = nil
    @Published var plunderEffectTrigger: UUID = UUID()
    @Published var npcShakeActive: Bool = false
    @Published var forceCameraFocus: Bool = false
    // === ここから追加: sp-decay 用（任意マスレベルダウン） ===
    @Published var isSelectingLandLevelChangeTarget: Bool = false
    @Published var landLevelChangeCandidateTiles: Set<Int> = []
    @Published var pendingLandLevelChangeTile: Int? = nil
    // === 単体ダメージ系スペル（大嵐／落雷など）用 ===
    @Published var isSelectingDamageTarget: Bool = false
    @Published var damageCandidateTiles: Set<Int> = []
    @Published var pendingDamageTile: Int? = nil
    @Published var pendingDamageAmount: Int = 0
    @Published var pendingDamageEffect: BoardWideSpellEffectKind? = nil
    @Published var pendingDamageSpellName: String? = nil
    @Published var isSelectingPoisonTarget: Bool = false
    @Published var poisonCandidateTiles: Set<Int> = []
    @Published var pendingPoisonTile: Int? = nil
    @Published var pendingPoisonSpellName: String? = nil
    @Published var isShowingBattleSpellEffect: Bool = false
    @Published var battleSpellEffectID: UUID = UUID()
    private var pendingBranchDestination: Int? = nil
    @Published var isSelectingCleanseTarget: Bool = false
    @Published var cleanseCandidateTiles: Set<Int> = []
    @Published var pendingCleanseTile: Int? = nil
    @Published var pendingCleanseSpellName: String? = nil
    @Published var activeBoardWideEffect: BoardWideSpellEffectKind? = nil
    @Published var isShowingDiceGlitch: Bool = false
    @Published var diceGlitchNumber: Int? = nil
    // === ここから追加: sp-devastation 用（通行量 0） ===
    @Published var isSelectingLandTollZeroTarget: Bool = false
    @Published var landTollZeroCandidateTiles: Set<Int> = []
    @Published var pendingLandTollZeroTile: Int? = nil
    // ★ 追加: sp-devastation などで通行量が 0 になっているマス
    @Published var devastatedTiles: Set<Int> = []
    // === ここから追加: sp-harvest 用（通行量 2倍） ===
    @Published var isSelectingLandTollDoubleTarget: Bool = false
    @Published var landTollDoubleCandidateTiles: Set<Int> = []
    @Published var pendingLandTollDoubleTile: Int? = nil
    /// sp-harvest で「収穫済み（通行量2倍）」になっているマス
    @Published var harvestedTiles: Set<Int> = []
    @Published var focusedHandIndex: Int = 0
    @Published var handDragOffset: CGFloat = 0
    
    private var spellPool: [Card] = []
    private var creaturePool: [Card] = []
    private var moveDir: [Dir] = [.cw, .cw]
    private var branchCameFrom: Int? = nil
    private var nextForcedRoll: [Int?] = [nil, nil]
    private var stepsLeft: Int = 0
    private var goldRef: WritableKeyPath<Player, Int> { \.gold }
    private var forceRollToOneFor: [Bool] = [false, false]
    private var pendingBattleAttacker: Int? = nil
    private var pendingBattleDefender: Int? = nil
    private var pendingSpellCard: Card? = nil
    private var pendingSpellOwner: Int? = nil
    private var pendingSpellHandIndex: Int? = nil
    private var pendingSpellCost: Int = 0
    private var willPoisonDefender: Bool = false
    private var plunderAnimationTask: Task<Void, Never>? = nil
    private let CROSS_NODE = 4
    private let CROSS_CHOICES = [3, 5, 27, 28]
    private let CHECKPOINTS: Set<Int> = [0, 4, 20]
    private let nextCW: [Int] = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0,
        17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 4, 29, 30, 16
    ]
    
    private let nextCCW: [Int] = [
        15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        30, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 4, 28, 29
    ]
    
    // チェックポイントのマスid指定
    private let HOME_NODE = 0
    private let CP1_NODE  = 4
    private let CP2_NODE  = 20
    
    let sideCount: Int = 5
    let tileCount: Int
    var levelUpCost: [Int: Int] { [2: 30, 3: 60, 4: 140, 5: 300] }

    private var decks: [[Card]] = [[], []]
    @Published var hands: [[Card]] = [[], []]
    
    init(selectedDeck: DeckList? = nil) {
        self.tileCount = 31  // RingBoardView のグラフと一致させる
        self.owner = Array(repeating: nil, count: tileCount)
        self.level = Array(repeating: 0, count: tileCount)
        self.creatureSymbol = Array(repeating: nil, count: tileCount)
        self.hp = Array(repeating: 0, count: tileCount)
        self.hpMax = Array(repeating: 0, count: tileCount)
        self.aff = Array(repeating: 0, count: tileCount)
        self.pow = Array(repeating: 0, count: tileCount)
        self.dur = Array(repeating: 0, count: tileCount)
        self.rDry = Array(repeating: 0, count: tileCount)
        self.rWat = Array(repeating: 0, count: tileCount)
        self.rHot = Array(repeating: 0, count: tileCount)
        self.rCold = Array(repeating: 0, count: tileCount)
        self.cost = Array(repeating: 1, count: tileCount)
        self.toll = Array(repeating: 0, count: tileCount)
        self.poisonedTiles = Array(repeating: false, count: tileCount)
        self.devastatedTiles = []
        self.harvestedTiles = []
        self.focusedHandIndex = 0
        self.handDragOffset = 0
        
        let initialPlayerDeck = selectedDeck ?? DeckList.defaultBattleDeck
        cardStates[0].deckList = initialPlayerDeck
        
        //NPCテスト
        cardStates[1].collection.add("cre-defaultBeardedDragon", count: 30)
        cardStates[1].collection.add("sp-dice2", count: 20)
        cardStates[1].deckList.creatureSlots = [
            "cre-defaultBeardedDragon": 35
        ]
        cardStates[1].deckList.spellSlots = [
            "sp-decay": 25
        ]
        
        //NPCデッキ
//        cardStates[1].collection.add("cre-defaultLizard", count: 30)
//        cardStates[0].collection.add("cre-defaultCrocodile", count: 30)
//        cardStates[1].collection.add("cre-defaultTurtle", count: 30)
//        cardStates[1].collection.add("cre-defaultBeardedDragon", count: 30)
//        cardStates[1].collection.add("cre-defaultHornedFrog", count: 30)
//        cardStates[1].collection.add("cre-defaultGreenIguana", count: 30)
//        cardStates[1].collection.add("cre-defaultBallPython", count: 30)
//        cardStates[1].collection.add("sp-hardFang", count: 5)
//        cardStates[1].collection.add("sp-bigScale", count: 5)
//        cardStates[1].collection.add("sp-deleteHand", count: 5)
//        cardStates[1].collection.add("sp-doubleDice", count: 5)
//        cardStates[1].collection.add("sp-firstStrike", count: 5)
//        
//        cardStates[1].deckList.creatureSlots = [
//            "cre-defaultLizard": 5,
//            "cre-defaultCrocodile": 5,
//            "cre-defaultTurtle": 5,
//            "cre-defaultBeardedDragon": 5,
//            "cre-defaultHornedFrog": 5,
//            "cre-defaultGreenIguana": 5,
//            "cre-defaultBallPython": 5
//        ]
//        cardStates[1].deckList.spellSlots = [
//            "sp-hardFang": 5,
//            "sp-bigScale": 5,
//            "sp-deleteHand": 5,
//            "sp-doubleDice": 5,
//            "sp-firstStrike": 5
//        ]
        
        for pid in 0...1 {
            decks[pid] = cardStates[pid].deckList.buildDeckCards()
        }
        // 初期手札3枚
        for pid in 0...1 {
            for _ in 0..<3 { drawOne(for: pid) }
        }

        startTurnIfNeeded()
        self.focusTile = players[turn].pos
        self.terrain = buildFixedTerrain()
    }
    
// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　その他
// MARK: ---------------------------------------------------------------------------
    // ポップアップを閉じる
    func closeCheckpointOverlay() {
        showCheckpointOverlay = false
        checkpointMessage = nil
    }
    
    func startCreatureSwap(from tile: Int) {
        creatureMenuTile = tile
        isSelectingSwapCreature = true
        showCreatureMenu = false      // メニューは一旦閉じる
    }

    func cancelCreatureSwap() {
        isSelectingSwapCreature = false
        // creatureMenuTile は残しても消してもどちらでもOK（好み）
    }

    /// 止まったときに自軍マスならメニューを開く
    func openCreatureMenuIfMyTile(_ tile: Int) {
        // 自軍＆クリーチャーがいるマスだけ開く
        if owner.indices.contains(tile),
           owner[tile] == turn,
           creatureSymbol.indices.contains(tile),
           creatureSymbol[tile] != nil {
            showCreatureMenu = true
            creatureMenuTile = tile
        }
    }

    /// 手札タップで交換候補をセット（既存の pendingSwapHandIndex を使う想定）
    func selectSwapHandIndex(_ idx: Int) {
        guard isSelectingSwapCreature else { return }
        pendingSwapHandIndex = idx
        isSelectingSwapCreature = false
        // → このあと既存の「交換しますか？」ダイアログが出る
    }
    
// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　ターン管理
// MARK: ---------------------------------------------------------------------------
    func endTurn() {
        // ★ プレイヤーが敵マスで「戦闘する」を選んだものの、
        //   カードを選ばずに End を押した場合は、自動で通行料を払ってから終了
        if turn == 0,
           phase == .moved,
           let t = landedOnOpponentTileIndex,
           expectBattleCardSelection {

            if let own = owner.indices.contains(t) ? owner[t] : nil {
                transferToll(from: turn, to: own, tile: t)
                battleResult = "通行料を奪われた"
            }
            landedOnOpponentTileIndex = nil
            expectBattleCardSelection = false
            canEndTurn = true
        }

        showSpecialMenu = false

        if turn == 0,
           isForcedSaleMode {
            pushCenterMessage("通行料を支払えません\n売却地を選択（現在:- \(debtAmount) G）")
            return
        }

        beginTurnTransition()
    }
    
    func beginTurnTransition() {
        guard !isTurnTransition else { return }
        isTurnTransition = true

        // ★ 3秒後にターン交代＆回復シーケンス開始
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            finishTurnTransition()
        }
    }

    func finishTurnTransition() {
        guard phase == .moved else { return }
        turn = 1 - turn
        phase = .ready
        lastRoll = 0
        Task { @MainActor in
            await self.runHealSequenceAndStartTurn()
        }
    }
    
    @MainActor
    private func runHealSequenceAndStartTurn() async {
        isTurnTransition = false
        try? await Task.sleep(nanoseconds: 300_000_000)

        // --------------------------------------------------
        // ① 毒ダメージ（そのクリーチャーの持ち主のターンだけ）
        // --------------------------------------------------
        var poisonMap: [Int: Int] = [:]

        for i in 0..<tileCount {
            guard owner.indices.contains(i),
                  owner[i] == turn,                         // ★ 持ち主のターンのみ
                  poisonedTiles.indices.contains(i),
                  poisonedTiles[i] == true,
                  hpMax.indices.contains(i), hpMax[i] > 0,
                  hp.indices.contains(i), hp[i] > 0
            else { continue }

            let raw = hpMax[i] * 20 / 100
            let dmg = max(1, raw)
            guard dmg > 0 else { continue }

            poisonMap[i] = dmg
        }

        if !poisonMap.isEmpty {
            isHealingAnimating = true

            let sequence = poisonMap.keys.sorted()
            for tile in sequence {
                guard let dmg = poisonMap[tile], dmg > 0 else { continue }

                // 実際のHP更新
                let beforeHP = hp[tile]
                let newHP = max(0, beforeHP - dmg)
                if newHP != beforeHP {
                    hp[tile] = newHP
                    if var c = creatureOnTile[tile] {
                        c.hp = newHP
                        creatureOnTile[tile] = c
                    }
                    hp = hp
                }

                // HP0になったらそのマスのクリーチャーは死亡＋毒解除
                if newHP <= 0 {
                    clearCreatureInfo(at: tile,
                                      clearOwnerAndLevel: true,
                                      resetToll: true)
                    if poisonedTiles.indices.contains(tile) {
                        poisonedTiles[tile] = false
                    }
                }

                // カメラを寄せる
                focusTile = tile

                // ★ 毒エフェクト＆ダメージ表示
                spellEffectTile = tile
                spellEffectKind = .poison
                healingAmounts = [tile: -dmg]

                // SpellEffectScene と数字を同時に出す
                try? await Task.sleep(nanoseconds: 1_000_000_000)

                healingAmounts.removeAll()
                spellEffectTile = nil

                try? await Task.sleep(nanoseconds: 300_000_000)
            }

            isHealingAnimating = false
        }
        
        // --------------------------------------------------
        // ② このあと「通常の回復シーケンス」
        // --------------------------------------------------
        var healMap: [Int: Int] = [:]

        for i in 0..<tileCount {
            guard owner.indices.contains(i),
                  owner[i] == turn,
                  hpMax.indices.contains(i),
                  hpMax[i] > 0,
                  hp.indices.contains(i),
                  hp[i] < hpMax[i],
                  aff.indices.contains(i) else { continue }

            let heal = aff[i] / 2
            guard heal > 0 else { continue }

            healMap[i] = heal
        }

        // 一つも回復がなければ、そのまま通常処理へ
        if healMap.isEmpty {
            startTurnIfNeeded()
            focusTile = players[turn].pos
            if turn == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    Task { await self.runCpuAuto() }
                }
            }
            // isTurnTransition はすでに false 済み
            return
        }

        // --- 回復アニメーション開始 ---
        isHealingAnimating = true

        let sequence = healMap.keys.sorted()
        for tile in sequence {
            guard let heal = healMap[tile], heal > 0 else { continue }

            let beforeHP = hp[tile]
            let newHP = min(hpMax[tile], beforeHP + heal)
            if newHP != beforeHP {
                hp[tile] = newHP
                if var c = creatureOnTile[tile] {
                    c.hp = newHP
                    creatureOnTile[tile] = c
                }
                hp = hp
            }

            focusTile = tile
            healingAmounts = [tile: heal]    // 回復はプラス値

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            healingAmounts.removeAll()
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        isHealingAnimating = false

        startTurnIfNeeded()
        focusTile = players[turn].pos
        if turn == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task { await self.runCpuAuto() }
            }
        }
    }

    
    func actionEndTurnFromSpecialNode() {
        // TODO: ターン終了の処理
        showSpecialMenu = false
        currentSpecialKind = nil
        endTurn()
    }

// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　山札・手札
// MARK: ---------------------------------------------------------------------------
    
    /// 山札から1枚ランダムに抜き取って返す（手札にはまだ追加しない）
    private func drawOneFromDeck(for pid: Int) -> Card? {
        guard !decks[pid].isEmpty else { return nil }
        let idx = Int.random(in: 0..<decks[pid].count)
        return decks[pid].remove(at: idx)
    }

    /// 従来の「即手札に加える」ドロー（スペル用など）
    private func drawOne(for pid: Int) {
        guard let picked = drawOneFromDeck(for: pid) else { return }
        hands[pid].append(picked)
    }
    
    /// プレイヤー用：カードをn枚、ターン開始ドローアニメと同じ方式で順番に表示
    func queuePreviewDraws(_ n: Int, for pid: Int) {
        // 現状はプレイヤー(0)専用。CPUなら即ドローでフォールバック
        guard pid == 0 else {
            for _ in 0..<n { drawOne(for: pid) }
            if pid == turn { handleHandOverflowIfNeeded() }
            return
        }

        guard n > 0 else { return }

        var picked: [Card] = []
        for _ in 0..<n {
            if let c = drawOneFromDeck(for: pid) {
                picked.append(c)
            }
        }
        guard !picked.isEmpty else { return }

        // まだアニメ中でない＆キューが空なら、1枚目をすぐ表示
        if drawPreviewCard == nil && pendingDrawPreviewQueue.isEmpty {
            let first = picked.removeFirst()
            drawPreviewCard = first
        }

        // 残り（0枚かもしれない）はキューへ
        if !picked.isEmpty {
            pendingDrawPreviewQueue.append(contentsOf: picked)
        }
    }
    
    func confirmDrawPreview() {
        guard let card = drawPreviewCard else { return }
        drawPreviewCard = nil
        hands[0].append(card)
        handleHandOverflowIfNeeded()

        // ★ まだキューが残っていれば、少し待って次のアニメを開始
        if !pendingDrawPreviewQueue.isEmpty {
            let next = pendingDrawPreviewQueue.removeFirst()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒ほど待つ
                drawPreviewCard = next
            }
        }
    }
    
    func startTurnIfNeeded() {
        guard phase == .ready else { return }

        // ★ ターン開始ドロー：プレイヤーだけプレビュー表示
        guard let picked = drawOneFromDeck(for: turn) else { return }

        if turn == 0 {
            // あなたのターン：まず中央に表示して、OK後に手札へ
            drawPreviewCard = picked
        } else {
            // CPUターン：従来通り即手札へ
            hands[turn].append(picked)
            handleHandOverflowIfNeeded()
        }
    }
    
    func confirmPlaceCreatureFromHand(_ card: Card, at tile: Int, by pid: Int) {
        guard canPlaceCreature(at: tile),
              owner.indices.contains(tile),
              owner[tile] == nil else {
            return
        }

        guard paySummonCostIfNeeded(for: card, by: pid) else {
            return
        }

        guard placeCreature(from: card, at: tile, by: pid) else {
            return
        }
        
        if let i = hands[pid].firstIndex(of: card) {
            hands[pid].remove(at: i)
        }

        canEndTurn = true
        showCreatureMenu = false
        creatureMenuTile = nil
    }
    
    /// 手札上限処理（>5 のとき捨てフェーズ等へ）
    private func handleHandOverflowIfNeeded() {
        if hands[turn].count > 5 {
            mustDiscardFor = turn
        }
    }

    func discard(_ card: Card, for pid: Int) {
        if let idx = hands[pid].firstIndex(of: card) {
            hands[pid].remove(at: idx)
        }
        mustDiscardFor = nil
    }
    
    func openCard(_ card: Card) {
        presentingCard = card
        if let idx = hands.indices.contains(turn) ? hands[turn].firstIndex(of: card) : nil {
            focusedHandIndex = idx
        }
        SoundManager.shared.playHandViewSound()
    }

    // ★ 追加：スペルショップからカード詳細を開く用
    func openShopSpellDetail(_ spell: ShopSpell) {
        guard let def = CardDatabase.definition(for: spell.id) else { return }
        let card = def.makeInstance()
        shopSpellForDetail = spell
        openCard(card)
    }
    
    func closeCardPopup() {
        presentingCard = nil
        shopSpellForDetail = nil
    }
    
    func spellDescription(for card: Card) -> String {
        // スペルじゃなければ空文字
        guard let effect = card.spell else {
            return ""
        }
        return spellDescription(effect)
    }

    func spellDescription(_ effect: SpellEffect) -> String {
        switch effect {
        case .fixNextRoll(let n):
            return "次のサイコロの出目を \(n) に固定する"
        case .doubleDice:
            return "次のターン、サイコロを2つ振ることができる"

        case .buffPower(let n):
            return "この戦闘中、戦闘力を \(n) 上昇させる"
        case .buffDefense(let n):
            return "この戦闘中、耐久力を \(n) 上昇させる"
        case .firstStrike:
            return "この戦闘で先に攻撃を行う"
        case .poison:
            return "敵クリーチャーに毎ターン最大HPの20%の毒ダメージを付与する"
        case .reflectSkill:
            return "敵の特殊スキルを跳ね返す"

        case .teleport:
            return "盤上の任意のマスへワープする"
        case .healHP(let n):
            return "HPを \(n) 回復する"

        case .drawCards(let n):
            return "自分の手札を \(n) 枚引く"
        case .discardOpponentCards(let n):
            return "相手の手札を \(n) 枚捨てさせる"

        case .fullHealAnyCreature:
            return "任意のマスのクリーチャーのHPを全回復させる"
        case .changeLandLevel:
            return "任意の土地のレベルを1下げる"
        case .setLandTollZero:
            return "任意の土地の通行料を0にする"
        case .multiplyLandToll:
            return "任意の土地の通行料を2倍にする"
        case .damageAnyCreature(let n):
            return "任意のマスのクリーチャーに \(n) ダメージを与える"
        case .poisonAnyCreature:
            return "任意のマスのクリーチャーを毒状態にする"
        case .cleanseTileStatus:
            return "マスにかかっている効果を解除する"

        case .gainGold(let n):
            return "\(n)GOLDを獲得する"
        case .stealGold(let n):
            return "相手から \(n)GOLD 奪い、自分のGOLDに加える"

        case .inspectCreature:
            return "任意の相手クリーチャーのステータスを確認できる"

        case .aoeDamageByResist(let category, let th, let n):
            let label: String
            switch category {
            case .dry:   label = "乾耐性"
            case .water: label = "水耐性"
            case .heat:  label = "熱耐性"
            case .cold:  label = "冷耐性"
            }
            return "\(label)\(th)以上の全キャラクターに \(n) ダメージを与える"

        case .changeTileAttribute(let kind):
            let label: String
            switch kind {
            case .normal: label = "normal"
            case .dry:    label = "dry"
            case .water:  label = "water"
            case .heat:   label = "heat"
            case .cold:   label = "cold"
            }
            return "任意のマスを \(label) マスに変える"

        case .purgeAllCreatures:
            return "自軍を含む全てのマスのクリーチャーを破壊する"
        }
    }
    
    /// 中央オーバーレイに短文を出す（既存の仕組みに繋いでください）
    private func pushCenterMessage(_ text: String) {
        battleResult = text
        logs.append(text)
    }
    
    /// スペル購入確定
    func confirmPurchaseSpell(_ spell: ShopSpell) {
        guard players[turn][keyPath: goldRef] >= spell.price else { return }
        addGold(-spell.price, to: turn)

        // 手札に追加：ShopSpell.id を CardID として扱う
        addSpellCardToHand(spellID: spell.id, displayName: spell.name)

        pushCenterMessage("\(spell.name) を購入 -\(spell.price)G")
        handleHandOverflowIfNeeded()  // 6枚超の処理があるなら実装済み関数を呼ぶ
        activeSpecialSheet = nil
        objectWillChange.send()
    }

    /// 手札へスペルを追加
    private func addSpellCardToHand(spellID: CardID, displayName: String) {
        if let def = CardDatabase.definition(for: spellID) {
            // CardDatabase から正しい効果つきの Card を生成
            let card = def.makeInstance()
            hands[turn].append(card)
        } else {
            // DBにないIDだった場合のフォールバック（暫定）
            let card = Card(
                id: spellID,
                kind: .spell,
                name: displayName,
                symbol: "sun.max.fill",
                stats: nil,
                spell: nil
            )
            hands[turn].append(card)
        }
    }
    
    // カードA（手札で選んだカード）から、確認ポップを出す
    func requestImmediateSwap(forSelectedCard card: Card) {
        // 手札インデックスを引く
        guard let idx = hands.indices.contains(turn) ? hands[turn].firstIndex(of: card) : nil else { return }
        // 支払い可能チェック
        guard canSwapCreature(withHandIndex: idx) else {
            battleResult = "GOLDが足りません"
            return
        }
        pendingSwapHandIndex = idx
    }

    // 交換実行（［交換］）
    func confirmSwapPending() {
        guard let idx = pendingSwapHandIndex else { return }
        if swapCreature(withHandIndex: idx) {
            pendingSwapHandIndex = nil
            showCreatureMenu = false
            creatureMenuTile = nil
            battleResult = "デジレプを交換しました"
        }
    }

    // 交換キャンセル（［キャンセル］）
    func cancelSwapPending() {
        // 今表示していた候補は捨てる
        pendingSwapHandIndex = nil

        // 交換対象マスが生きている場合は、再び「交換するデジレプを選択」フェーズへ戻す
        if creatureMenuTile != nil {
            isSelectingSwapCreature = true   // ← これで上部のテキストも再表示される
            // showCreatureMenu は false のままでOK（手札から選ぶフェーズなので）
        } else {
            // 念のため、対象マスが失われていた場合は完全リセット
            isSelectingSwapCreature = false
        }
    }

// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　サイコロ・移動
// MARK: ---------------------------------------------------------------------------
    func rollDice() {
        guard turn == 0, phase == .ready else { return }
        
        let r: Int
        if let forced = nextForcedRoll[turn] {
            // 強制出目が指定されている場合はそれを優先
            r = forced
        } else {
            if doubleDice[turn] {
                // ダイス2個 → 2〜12
                let d1 = Int.random(in: 1...6)
                let d2 = Int.random(in: 1...6)
                r = d1 + d2
            } else {
                // 通常 → 1〜6
                r = Int.random(in: 1...6)
            }
        }
        doubleDice[turn] = false
        nextForcedRoll[turn] = nil
        forceRollToOneFor[turn] = false
        lastRoll = r
        stepsLeft = r

        if players[turn].pos == CROSS_NODE, stepsLeft > 0 {
            focusTile = players[turn].pos
            branchSource = CROSS_NODE
            branchCandidates = CROSS_CHOICES
            phase = .branchSelecting
            recomputeBranchLandingHints()
            return
        }
        phase = .moving
        Task { await continueMoveAnimated() }
        focusTile = players[turn].pos
    }
    
    @MainActor
    func continueMoveAnimated() async {
        while stepsLeft > 0 {
            advanceOneStep()
            SoundManager.shared.playMoveSound()

            // 分岐UIが出たら入力待ちで中断（ここまでで1歩進んだ）
            if branchSource != nil {
                // ★ 分岐地点に寄せる
                focusTile = players[turn].pos
                return
            }

            focusTile = players[turn].pos

            try? await Task.sleep(nanoseconds: 400_000_000)
        }

        phase = .moved
        didStop(at: players[turn].pos, isYou: turn == 0)
        handleAfterMove()
        focusTile = players[turn].pos
    }
    
    private func handleAfterMove() {
        let t = players[turn].pos
        guard let own = owner[t], own != turn else {
            // 空き地 or 自分マス
            landedOnOpponentTileIndex = nil
            expectBattleCardSelection = false
            canEndTurn = true
            return
        }

        // 敵マスに止まった
        landedOnOpponentTileIndex = t

        // 攻撃側（= 今動いた側）が召喚可能なクリーチャーカードを持っているか
        let canSummonForBattle = hasSummonableCreature(for: turn)

        // 1) そもそも攻撃側がクリーチャーを持っていない → 共通で通行料
        if !canSummonForBattle {
            transferToll(from: turn, to: own, tile: t)
            battleResult = (turn == 1)
                ? "通行料を奪った"      // CPUが払ってあなたが受取
                : "通行料を奪われた"   // あなたが支払い
            landedOnOpponentTileIndex = nil
            expectBattleCardSelection = false
            canEndTurn = true
            return
        }

        // 2) CPUが攻撃側のときだけ「G不足チェック」を挟む
        if turn == 1 {
            let gold = players[1].gold

            // CPUの手札の中で「コストを払えるクリーチャー」が1枚でもあるか
            let hasAffordableCreature = hands[1].contains {
                $0.kind == .creature && (($0.stats?.cost ?? 0) <= gold)
            }

            if !hasAffordableCreature {
                // G不足で戦闘できない → 通行料処理
                transferToll(from: turn, to: own, tile: t)
                battleResult = "通行料を奪った"  // turn==1確定
                landedOnOpponentTileIndex = nil
                expectBattleCardSelection = false
                canEndTurn = true
                return
            }

            // コストを払える中で一番強いカードを選んで戦闘
            let attr = attributeAt(tile: t)
            if let creature = bestAffordableAttacker(in: hands[1], for: attr, gold: gold) {
                startBattle(with: creature)   // ここに来るときは必ず cost <= gold
                return
            } else {
                // 一応フォールバック：ありえないはずだけど、安全のため通行料
                transferToll(from: turn, to: own, tile: t)
                battleResult = "通行料を奪った"
                landedOnOpponentTileIndex = nil
                expectBattleCardSelection = false
                canEndTurn = true
                return
            }
        } else {
            // 3) プレイヤーが攻撃側のときの処理（元のロジックを維持）
            //   ※ここは今まで通りでOK。コスト不足かどうかは
            //     primaryActionや placeCreature 側で判定済み。

            // ★ プレイヤーは選択待ち（Endは有効のまま、"戦う"を押したら無効化）
            expectBattleCardSelection = false
            canEndTurn = true
        }
    }
    
    func bestAffordableAttacker(in hand: [Card], for attr: TileAttribute, gold: Int) -> Card? {
        // 「コストが払えるクリーチャー」の中から bestAttackerCard と同じロジックで最大値を取る
        let pool = hand.filter { card in
            guard card.kind == .creature else { return false }
            let cost = card.stats?.cost ?? 0
            return cost <= gold
        }

        return pool.max { lhs, rhs in
            let ls = lhs.stats ?? .defaultLizard
            let rs = rhs.stats ?? .defaultLizard
            let lScore = ls.power * 2 + resistValue(of: ls, for: attr) * 4
            let rScore = rs.power * 2 + resistValue(of: rs, for: attr) * 4
            return lScore < rScore
        }
    }

    func hasSummonableCreature(for pid: Int) -> Bool {
        guard hands.indices.contains(pid),
              players.indices.contains(pid) else { return false }
        let gold = players[pid].gold
        return hands[pid].contains {
            $0.kind == .creature && summonCost(of: $0) <= gold
        }
    }

    private func applyBranchChoice(_ chosenNext: Int) {
        // 方向決定
        if chosenNext == 3 || chosenNext == 27 {
            moveDir[turn] = .ccw
        } else if chosenNext == 5 || chosenNext == 28 {
            moveDir[turn] = .cw
        } else {
            // フォールバック（来ないはず）
            moveDir[turn] = .cw
        }

        pendingBranchDestination = chosenNext
    }
    
    // 選択肢ごとの進行方向
    private func dirForCandidate(_ chosenNext: Int) -> Dir {
        if chosenNext == 3 || chosenNext == 27 { return .ccw }
        if chosenNext == 5 || chosenNext == 28 { return .cw }
        return .cw
    }
    
    private func nextIndex(for pid: Int, from cur: Int) -> Int {
        switch moveDir[pid] {
        case .cw:  return nextCW[cur]
        case .ccw: return nextCCW[cur]
        }
    }
    
    // 方向を明示して「次マス」を返す純関数版（状態を変えない）
    private func nextIndex(for dir: Dir, from cur: Int) -> Int {
        switch dir {
        case .cw:  return nextCW[cur]
        case .ccw: return nextCCW[cur]
        }
    }
    
    // 「この候補を選んだらどこに止まるか」をシミュレーション
    private func landingIfChoose(_ candidate: Int, from currentPos: Int, steps remaining: Int) -> Int {
        // candidate を選ぶとその場で 1 歩消費して candidate へ進む想定（applyBranchChoiceと同じ）
        var pos = candidate
        var rem = max(0, remaining - 1)
        let dir = dirForCandidate(candidate)

        while rem > 0 {
            pos = nextIndex(for: dir, from: pos)
            rem -= 1
            // ※もし将来「2回目の分岐」を入れるなら、ここでさらに分岐処理を差し込む
        }
        return pos
    }

    // 分岐UI表示中に、すべての候補の“着地マス”を算出して公開プロパティに入れる
    private func recomputeBranchLandingHints() {
        guard let src = branchSource, src == CROSS_NODE, phase == .branchSelecting else {
            branchLandingTargets = []
            return
        }
        // 現在の stepsLeft は「この分岐選択でさらに1歩消費される前」の残数
        let remaining = stepsLeft
        let cur = players[turn].pos
        let targets: Set<Int> = Set(branchCandidates.map { cand in
            landingIfChoose(cand, from: cur, steps: remaining)
        })
        branchLandingTargets = targets
    }
    
    // 既存の「次のマス」算出を利用して1歩進める
    private func advanceOneStep() {
        // まず通常の1歩前進
        let cur = players[turn].pos
        let next: Int
        if cur == CROSS_NODE, let pending = pendingBranchDestination {
            next = pending
            pendingBranchDestination = nil
        } else {
            next = nextIndex(for: turn, from: cur)
        }
        players[turn].pos = next
        stepsLeft -= 1
        awardCheckpointIfNeeded(entering: next, pid: turn)

        // 分岐ノードに入った & まだ動けるなら分岐処理
        if next == CROSS_NODE, stepsLeft > 0 {
            let cameFrom = cur
            // Uターン禁止（来た方向は候補から外す）
            let filtered = CROSS_CHOICES.filter { $0 != cameFrom }

            if turn == 0 {
                // プレイヤー: UI表示して停止
                branchCameFrom = cameFrom
                branchSource = CROSS_NODE
                branchCandidates = filtered
                phase = .branchSelecting
                recomputeBranchLandingHints()
                return
            } else {
                // CPU: passedCP2 の状態に応じて優先方向を絞る
                var base = filtered
                if passedCP2.indices.contains(1) {
                    if passedCP2[1] == false {
                        // まだCP2未通過 → 28/29 方向を優先（0始まりで 27/28）
                        let prefer: Set<Int> = [27, 28]
                        let narrowed = base.filter { prefer.contains($0) }
                        if !narrowed.isEmpty { base = narrowed }
                    } else {
                        // CP2通過済み → 3/5 方向を優先
                        let prefer: Set<Int> = [3, 5]
                        let narrowed = base.filter { prefer.contains($0) }
                        if !narrowed.isEmpty { base = narrowed }
                    }
                }
                // 最終候補からランダム選択→即適用（1歩消費して選択先へ）
                if let choice = base.randomElement() {
                    applyBranchChoice(choice)
                }
                // CPUは停止せず続行（stepsLeft が 0 になるか、以降の処理で停止）
            }
        }
    }
    
    func pickBranch(_ chosenNext: Int) {
        guard branchSource != nil else { return }
        
        if let came = branchCameFrom, chosenNext == came {
            return  // UIでは除外済みだが二重防御
        }
        // 方向確定＋1歩消費＋位置更新
        applyBranchChoice(chosenNext)

        // UIクリア
        branchSource = nil
        branchCandidates = []
        branchCameFrom = nil
        branchLandingTargets = []

        // 残りがあれば移動継続、なければ後処理へ
        if stepsLeft > 0 {
            phase = .moving
            Task { await continueMoveAnimated() }
        } else {
            phase = .moved
            handleAfterMove()
        }
    }
    
    // === 追加: 駒の移動完了時に特別マスか確認してメニューを開く ===
    func didStop(at index: Int, isYou: Bool) {
        // 自分のターンで止まった場合のみメニューを提示（必要ならCPUにも対応可）
        if isYou, let kind = specialNodeKind(for: index) {
            currentSpecialKind = kind
            showSpecialMenu = true
        } else {
            currentSpecialKind = nil
            showSpecialMenu = false
        }
        
        // ◆ 自軍クリーチャーマスなら CreatureMenuView を出したい
        if isYou,
           turn == 0,  // プレイヤーのターンだけ
           owner.indices.contains(index),
           owner[index] == 0,
           level.indices.contains(index),
           level[index] >= 1,
           creatureSymbol.indices.contains(index),
           creatureSymbol[index] != nil {

            // MyTileMenu ではなく、CreatureMenu 用の状態をセット
            creatureMenuTile = index
            showCreatureMenu = true

            // もし MyTileMenu を使わないなら閉じておく
            closeMyTileMenu()
        } else {
            showCreatureMenu = false
            creatureMenuTile = nil
            // MyTileMenu も閉じてよければここで
            closeMyTileMenu()
        }
    }
    
    // タイルに「入った」タイミングで呼ぶ
    private func awardCheckpointIfNeeded(entering index: Int, pid: Int) {
        // 1) CP通過フラグの更新（CP1/CP2それぞれ）
        if index == CP1_NODE {
            passedCP1[pid] = true
            if pid == 0 {
                // GOLDはまだ付与しないが、通過ポップアップは出す
                lastCheckpointGain = 0
                checkpointMessage = "CP1通過"
                showCheckpointOverlay = true
            }
            return
        }
        if index == CP2_NODE {
            passedCP2[pid] = true
            if pid == 0 {
                lastCheckpointGain = 0
                checkpointMessage = "CP2通過"
                showCheckpointOverlay = true
            }
            return
        }

        // 2) ホーム通過時：両方trueならGOLD付与してフラグをリセット
        if index == HOME_NODE {
            if passedCP1[pid] && passedCP2[pid] {
                let gain = checkpointReward(for: pid)
                players[pid].gold += gain
                passedCP1[pid] = false
                passedCP2[pid] = false

                if pid == 0 {
                    lastCheckpointGain = gain
                    checkpointMessage = "帰還しました。CP達成報酬 \(gain) GOLD"
                    showCheckpointOverlay = true
                }
            } else {
                // どちらか未達 → 何もしない（ポップアップも出さない）
            }
        }
    }

// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　カード使用
// MARK: ---------------------------------------------------------------------------
    
    func useSpellCard(_ card: Card, by pid: Int, targetTile: Int?) {
        // 1. 定義取得
        guard let def = CardDatabase.definition(for: card.id) else { return }

        // 2. GOLD コストを支払う
        guard tryPay(def.cost, by: pid) else {
            // ここでログやアラートなど
            battleResult = "GOLDが足りません（必要: \(def.cost)）"
            return
        }

        // 3. 実際の効果（あとで個別に実装していく）
        if let effect = def.spellEffect {
            applySpellEffect(effect, by: pid, targetTile: targetTile)
        }
    }
    
    private func spellCost(of card: Card) -> Int {
        CardDatabase.definition(for: card.id)?.cost ?? 0
    }
    
    private func equipmentCost(of card: Card) -> Int {
        if let s = card.stats {
            return s.cost
        }
        // stats がない spell 装備は定義から取得
        return CardDatabase.definition(for: card.id)?.cost ?? 0
    }
    
    private func summonCost(of card: Card) -> Int {
        max(0, card.stats?.cost ?? 0)
    }

    private func paySummonCostIfNeeded(for card: Card, by pid: Int) -> Bool {
        let price = summonCost(of: card)
        if price <= 0 { return true }

        if tryPay(price, by: pid) {
            return true
        } else {
            if pid == 0 {
                battleResult = "G不足（必要: \(price)）"
            }
            return false
        }
    }
    
    func useSpellPreRoll(_ card: Card, target: Int) {
        guard turn == 0,
              phase == .ready,
              card.kind == .spell else { return }
        guard (0...1).contains(target) else { return }
        guard let effect = card.spell else { return }
        
        // ★ 戦闘中専用
        if isBattleOnlySpell(card) {
            pushCenterMessage("戦闘中のみ使用できます")
            return
        }

        let cost = spellCost(of: card)

        switch effect {
        case .fixNextRoll(let n):
            guard (1...6).contains(n) else { return }
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            nextForcedRoll[target] = n
            if target == turn {
                pushCenterMessage("次のサイコロを \(n) に固定（コスト\(cost)）")
                showDiceGlitch(number: n)
            } else {
                pushCenterMessage("CPUの次のサイコロを \(n) に固定（コスト\(cost)）")
                showDiceGlitch(number: n)
            }
            consumeFromHand(card, for: 0)

        case .doubleDice:
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            doubleDice[target] = true
            if target == turn {
                pushCenterMessage("次のサイコロがダブルダイスになります（コスト\(cost)）")
            } else {
                pushCenterMessage("CPUの次のサイコロがダブルダイスになります（コスト\(cost)）")
            }
            consumeFromHand(card, for: 0)
            
        case .drawCards(let n):
            guard target == 0 else { break }    // 念のため CPU には使わせない
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            queuePreviewDraws(n, for: 0)
            pushCenterMessage("カードを \(n) 枚ドロー（コスト\(cost)）")
            consumeFromHand(card, for: 0)
            
        case .discardOpponentCards(_):
            let opponent = 1
            guard paySpellCostIfNeeded(cost, by: 0) else { return }

            if turn == 0 {
                if hands[opponent].isEmpty {
                    pushCenterMessage("相手の手札がありません")
                } else {
                    isSelectingOpponentHandToDelete = true
                    deletingTargetPlayer = opponent
                }
                consumeFromHand(card, for: 0)
            } else {
                let player = 0
                if let removed = hands[player].randomElement(),
                   let idx = hands[player].firstIndex(of: removed)
                {
                    hands[player].remove(at: idx)
                    deletePreviewCard = removed
                    battleResult = "このカードが削除されました"
                }
            }

        case .stealGold(let amount):
            guard applyPlunderSpell(amount: amount, cost: cost) else { return }
            consumeFromHand(card, for: 0)

        case .inspectCreature:
            guard target == 0 else { break }
            guard applyClairvoyanceSpell(for: 0, cost: cost) else { return }
            consumeFromHand(card, for: 0)
            
        case .fullHealAnyCreature:
            // 自軍の、HPが減っているマスだけを候補にする
            var candidates: Set<Int> = []

            for i in 0..<tileCount {
                guard owner.indices.contains(i),
                      owner[i] == 0,                   // 自軍
                      level.indices.contains(i),
                      level[i] > 0,                    // 何かしら置かれている
                      hp.indices.contains(i),
                      hpMax.indices.contains(i),
                      hp[i] < hpMax[i]                // ダメージを受けている
                else { continue }

                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("回復できるマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingFullHealTarget = true
                fullHealCandidateTiles = candidates
                // 既存の highlight を流用してボード側を強調
                branchLandingTargets = candidates
                battleResult = "回復するマスを選択してください"
            }
            
        case .changeLandLevel(let delta):
            // 今回は sp-decay（delta = -1）だけ対応
            guard delta < 0 else {
                pushCenterMessage("この土地レベル変更はできません")
                break
            }

            // レベル2以上のマスだけを候補にする（敵味方問わず）
            var candidates: Set<Int> = []
            for i in 0..<tileCount {
                guard level.indices.contains(i),
                      level[i] >= 2
                else { continue }
                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("レベルを下げられるマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingLandLevelChangeTarget = true
                landLevelChangeCandidateTiles = candidates
                pendingLandLevelChangeTile = nil
                // ボード側のハイライトに既存のプロパティを流用
                branchLandingTargets = candidates
                battleResult = "レベルを下げるマスを選択してください"
            }
            
        case .setLandTollZero:
            // 通行量 > 0 のマスだけを候補にする（敵味方・レベル問わず）
            var candidates: Set<Int> = []

            for i in 0..<tileCount {
                guard toll.indices.contains(i),
                      toll[i] > 0
                else { continue }
                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("通行量が設定されているマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingLandTollZeroTarget = true
                landTollZeroCandidateTiles = candidates
                branchLandingTargets = candidates   // ボード側のハイライトに流用
                battleResult = "通行量を 0 にするマスを選択してください"
            }
            
        case .multiplyLandToll(_):
            // 今回は 2.0 のみ想定だが、将来用に factor は一応受け取る
            var candidates: Set<Int> = []

            for i in 0..<tileCount {
                guard toll.indices.contains(i),
                      toll[i] > 0,
                      !devastatedTiles.contains(i),   // すでに 0 のマスは除外
                      !harvestedTiles.contains(i)     // 既に 2倍済みのマスも除外
                else { continue }
                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("通行量を 2 倍にできるマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingLandTollDoubleTarget = true
                landTollDoubleCandidateTiles = candidates
                pendingLandTollDoubleTile = nil
                branchLandingTargets = candidates
                battleResult = "通行量を 2 倍にするマスを選択してください"
            }

        case .damageAnyCreature(let n):
            beginDamageSpellSelection(amount: n, card: card, cost: cost)

        case .poisonAnyCreature:
            beginPoisonSpellSelection(card: card, cost: cost)

        case .cleanseTileStatus:
            beginCleanseSpellSelection(card: card, cost: cost)

        case .gainGold(let amount):
            guard applyTreasureGain(amount: amount, cost: cost) else { return }
            consumeFromHand(card, for: 0)

        case .teleport, .healHP,
             .aoeDamageByResist,
             .changeTileAttribute,
             .purgeAllCreatures:
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            pushCenterMessage("スペル『\(card.name)』の効果はまだ未実装です（コスト\(cost)だけ消費）")
            consumeFromHand(card, for: 0)

        // ★ 追加：万一新しいケースが増えてもここで拾う
        default:
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            pushCenterMessage("未対応のスペル効果です（コスト\(cost)だけ消費）")
            consumeFromHand(card, for: 0)
        }
    }

    func useSpellPreRoll(_ card: Card) {
        useSpellPreRoll(card, target: 0)
    }

    func useCardAfterMove(_ card: Card) {
        guard turn == 0, phase == .moved else { return }

        switch card.kind {
        case .spell:
            useSpellAfterMove(card)

        case .creature:
            if expectBattleCardSelection,
               landedOnOpponentTileIndex != nil {
                startBattle(with: card)
                return
            }

            let t = players[0].pos
            if owner[t] == nil, canPlaceCreature(at: t) {
                // ★ ここで支払い → 設置
                if paySummonCostIfNeeded(for: card, by: 0),
                   placeCreature(from: card, at: t, by: 0) {
                    consumeFromHand(card, for: 0)
                }
            }
        }
    }

    
    func useSpellAfterMove(_ card: Card) {
        guard turn == 0,
              phase == .moved,
              card.kind == .spell else { return }

        guard let effect = card.spell else { return }
        
        // ★ 戦闘中専用
        if isBattleOnlySpell(card) {
            pushCenterMessage("戦闘中のみ使用できます")
            return
        }

        let cost = spellCost(of: card)

        switch effect {

        case .fixNextRoll(let n) where (1...6).contains(n):
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            nextForcedRoll[0] = n
            pushCenterMessage("次のサイコロを \(n) に固定（コスト\(cost)）")
            consumeFromHand(card, for: 0)

        case .doubleDice:
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            doubleDice[0] = true
            pushCenterMessage("次のサイコロがダブルダイスになります（コスト\(cost)）")
            consumeFromHand(card, for: 0)
            
        case .drawCards(let n):
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            queuePreviewDraws(n, for: 0)
            pushCenterMessage("カードを \(n) 枚ドロー（コスト\(cost)）")
            consumeFromHand(card, for: 0)
            
        case .discardOpponentCards(_):
            // プレイヤー側
            let opponent = 1

            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            if hands[opponent].isEmpty {
                pushCenterMessage("相手の手札がありません")
            } else {
                // NPC手札選択モードへ
                isSelectingOpponentHandToDelete = true
                deletingTargetPlayer = opponent
            }
            consumeFromHand(card, for: 0)
            
        case .stealGold(let amount):
            guard applyPlunderSpell(amount: amount, cost: cost) else { return }
            consumeFromHand(card, for: 0)

        case .inspectCreature:
            guard applyClairvoyanceSpell(for: 0, cost: cost) else { return }
            consumeFromHand(card, for: 0)
            
        case .fullHealAnyCreature:
            var candidates: Set<Int> = []

            for i in 0..<tileCount {
                guard owner.indices.contains(i),
                      owner[i] == 0,
                      level.indices.contains(i),
                      level[i] > 0,
                      hp.indices.contains(i),
                      hpMax.indices.contains(i),
                      hp[i] < hpMax[i]
                else { continue }

                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("回復できるマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingFullHealTarget = true
                fullHealCandidateTiles = candidates
                // 既存の highlight を流用してボード側を強調
                branchLandingTargets = candidates
                battleResult = "回復するマスを選択してください"
            }
            
        case .changeLandLevel(let delta):
            // 今回は sp-decay（delta = -1）だけ対応
            guard delta < 0 else {
                pushCenterMessage("この土地レベル変更はできません")
                break
            }

            // レベル2以上のマスだけを候補にする（敵味方問わず）
            var candidates: Set<Int> = []
            for i in 0..<tileCount {
                guard level.indices.contains(i),
                      level[i] >= 2
                else { continue }
                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("レベルを下げられるマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingLandLevelChangeTarget = true
                landLevelChangeCandidateTiles = candidates
                pendingLandLevelChangeTile = nil
                // ボード側のハイライトに既存のプロパティを流用
                branchLandingTargets = candidates
                battleResult = "レベルを下げるマスを選択してください"
            }
            
        case .setLandTollZero:
            // 通行量 > 0 のマスだけを候補にする（敵味方・レベル問わず）
            var candidates: Set<Int> = []

            for i in 0..<tileCount {
                guard toll.indices.contains(i),
                      toll[i] > 0
                else { continue }
                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("通行量が設定されているマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingLandTollZeroTarget = true
                landTollZeroCandidateTiles = candidates
                branchLandingTargets = candidates   // ボード側のハイライトに流用
                battleResult = "通行量を 0 にするマスを選択してください"
            }
            
        case .multiplyLandToll(_):
            // 今回は 2.0 のみ想定だが、将来用に factor は一応受け取る
            var candidates: Set<Int> = []

            for i in 0..<tileCount {
                guard toll.indices.contains(i),
                      toll[i] > 0,
                      !devastatedTiles.contains(i),   // すでに 0 のマスは除外
                      !harvestedTiles.contains(i)     // 既に 2倍済みのマスも除外
                else { continue }
                candidates.insert(i)
            }

            if candidates.isEmpty {
                pushCenterMessage("通行量を 2 倍にできるマスがありません")
            } else {
                guard beginPendingSpellUsage(card: card, owner: 0, cost: cost) else { return }
                isSelectingLandTollDoubleTarget = true
                landTollDoubleCandidateTiles = candidates
                pendingLandTollDoubleTile = nil
                branchLandingTargets = candidates
                battleResult = "通行量を 2 倍にするマスを選択してください"
            }

        case .damageAnyCreature(let n):
            beginDamageSpellSelection(amount: n, card: card, cost: cost)

        case .poisonAnyCreature:
            beginPoisonSpellSelection(card: card, cost: cost)

        case .cleanseTileStatus:
            beginCleanseSpellSelection(card: card, cost: cost)

        case .gainGold(let amount):
            guard applyTreasureGain(amount: amount, cost: cost) else { return }
            consumeFromHand(card, for: 0)

        case .teleport, .healHP,
             .aoeDamageByResist,
             .changeTileAttribute,
             .purgeAllCreatures:
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            pushCenterMessage("スペル『\(card.name)』の効果はまだ未実装です（コスト\(cost)だけ消費）")
            consumeFromHand(card, for: 0)

        // ★ 追加：万一新しいケースが増えてもここで拾う
        default:
            guard paySpellCostIfNeeded(cost, by: 0) else { return }
            pushCenterMessage("未対応のスペル効果です（コスト\(cost)だけ消費）")
            consumeFromHand(card, for: 0)
        }
    }

    private func beginDamageSpellSelection(amount: Int,
                                           card: Card,
                                           cost: Int,
                                           owner: Int = 0) {
        var candidates: Set<Int> = []

        for i in 0..<tileCount {
            guard creatureSymbol.indices.contains(i),
                  creatureSymbol[i] != nil,
                  hp.indices.contains(i),
                  hp[i] > 0 else { continue }
            candidates.insert(i)
        }

        if candidates.isEmpty {
            pushCenterMessage("ダメージを与えられるマスがありません")
            return
        }

        guard beginPendingSpellUsage(card: card, owner: owner, cost: cost) else { return }

        isSelectingDamageTarget = true
        damageCandidateTiles = candidates
        pendingDamageTile = nil
        pendingDamageAmount = amount
        pendingDamageEffect = boardWideEffectKind(for: card.id)
        pendingDamageSpellName = card.name
        branchLandingTargets = candidates
        battleResult = "『\(card.name)』の対象マスを選択してください"
    }

    private func beginPoisonSpellSelection(card: Card,
                                           cost: Int,
                                           owner: Int = 0) {
        var candidates: Set<Int> = []

        for i in 0..<tileCount {
            guard creatureSymbol.indices.contains(i),
                  creatureSymbol[i] != nil,
                  hp.indices.contains(i),
                  hp[i] > 0,
                  poisonedTiles.indices.contains(i),
                  poisonedTiles[i] == false else { continue }
            candidates.insert(i)
        }

        if candidates.isEmpty {
            pushCenterMessage("毒を付与できるマスがありません")
            return
        }

        guard beginPendingSpellUsage(card: card, owner: owner, cost: cost) else { return }

        isSelectingPoisonTarget = true
        poisonCandidateTiles = candidates
        pendingPoisonTile = nil
        pendingPoisonSpellName = card.name
        branchLandingTargets = candidates
        battleResult = "『\(card.name)』の対象マスを選択してください"
    }

    private func beginCleanseSpellSelection(card: Card,
                                            cost: Int,
                                            owner: Int = 0) {
        var candidates: Set<Int> = []

        for i in 0..<tileCount {
            if tileHasCleanseStatus(i) {
                candidates.insert(i)
            }
        }

        if candidates.isEmpty {
            pushCenterMessage("解除できるマスがありません")
            return
        }

        guard beginPendingSpellUsage(card: card, owner: owner, cost: cost) else { return }

        isSelectingCleanseTarget = true
        cleanseCandidateTiles = candidates
        pendingCleanseTile = nil
        pendingCleanseSpellName = card.name
        branchLandingTargets = candidates
        battleResult = "『\(card.name)』の対象マスを選択してください"
    }

    private func boardWideEffectKind(for cardID: CardID) -> BoardWideSpellEffectKind? {
        switch cardID {
        case "sp-greatStorm":
            return .storm
        case "sp-disaster":
            return .disaster
        case "sp-clairvoyance":
            return .clairvoyance
        default:
            return nil
        }
    }

    @discardableResult
    private func applyTreasureGain(amount: Int, cost: Int) -> Bool {
        guard paySpellCostIfNeeded(cost, by: 0) else { return false }
        let gain = max(0, amount)
        addGold(gain, to: 0)
        pushCenterMessage("\(gain)GOLDを獲得（コスト\(cost)）")
        triggerBoardWideEffect(.treasure)
        return true
    }

    @discardableResult
    private func applyPlunderSpell(amount: Int, cost: Int) -> Bool {
        guard paySpellCostIfNeeded(cost, by: 0) else { return false }
        let stolen = stealGold(amount: amount, from: 1, to: 0, showVisual: true)
        if stolen > 0 {
            pushCenterMessage("\(stolen)GOLDを奪った（コスト\(cost)）")
        } else {
            pushCenterMessage("奪えるGOLDがありません（コスト\(cost)だけ消費）")
        }
        return true
    }

    @discardableResult
    private func stealGold(amount: Int, from victim: Int, to thief: Int, showVisual: Bool) -> Int {
        guard players.indices.contains(victim),
              players.indices.contains(thief) else { return 0 }
        let stolen = max(0, min(players[victim].gold, amount))
        guard stolen > 0 else { return 0 }
        addGold(-stolen, to: victim)
        addGold(+stolen, to: thief)
        if showVisual, thief == 0, victim == 1 {
            triggerPlunderVisual(at: players[victim].pos)
        }
        return stolen
    }

    private func triggerPlunderVisual(at tile: Int) {
        SoundManager.shared.playBoardWideEffectSound(.treasure)
        plunderAnimationTask?.cancel()
        plunderAnimationTask = nil

        let previousFocus = focusTile
        forceCameraFocus = true
        focusTile = tile
        plunderEffectTile = tile
        plunderEffectTrigger = UUID()
        npcShakeActive = true

        plunderAnimationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self.plunderEffectTile = nil
            self.npcShakeActive = false

            let restoreTile = previousFocus ?? self.players[self.turn].pos
            if restoreTile != tile {
                self.focusTile = restoreTile
            }

            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            self.forceCameraFocus = false
            self.plunderAnimationTask = nil
        }
    }

    /// 山札ショップなどから買ったスペルの共通適用口
    private func applySpellEffect(_ effect: SpellEffect, by pid: Int, targetTile: Int?) {
        switch effect {

        // ① ダイス固定
        case let .fixNextRoll(n):
            guard (1...6).contains(n),
                  (0...1).contains(pid) else { return }
            nextForcedRoll[pid] = n
            pushCenterMessage("次のサイコロを \(n) に固定")

        // ② GOLD獲得
        case let .gainGold(n):
            addGold(n, to: pid)
            pushCenterMessage("\(n)GOLD を獲得")
            triggerBoardWideEffect(.treasure)

        // ③ GOLD奪取（とりあえずシンプルに実装）
        case let .stealGold(n):
            let other = 1 - pid
            let stolen = stealGold(amount: n, from: other, to: pid, showVisual: pid == 0 && other == 1)
            pushCenterMessage("\(stolen)GOLD を奪った")

        case .inspectCreature:
            performClairvoyance(for: pid)
            
        case let .drawCards(n):
            guard (0...1).contains(pid) else { return }
            for _ in 0..<n {
                drawOne(for: pid)
            }
            pushCenterMessage("プレイヤー\(pid) がカードを \(n) 枚ドロー")
            if pid == turn {
                handleHandOverflowIfNeeded()
            }

        // それ以外はあとで個別実装
        default:
            pushCenterMessage("このスペル効果はまだ未実装です")
        }
    }
    
    func useDoubleDiceSpellForPlayer() {
        doubleDice[0] = true
    }
    
    @discardableResult
    func applyBattleEquipment(_ card: Card, by user: Int) -> Bool {

        // ② 戦闘データが揃っているか
        guard var left = battleLeft,
              var right = battleRight,
              let attacker = pendingBattleAttacker else { return false }

        let defender = 1 - attacker
        let isAttacker = (user == attacker)
        let isDefender = (user == defender)

        // ★ 先制：防御側のみ使用可
        if card.id == "sp-firstStrike" {
            guard isDefender else {
                if user == 0 {
                    battleResult = "『先制』は防御側のみ使用できます"
                }
                return false
            }
            defenderHasFirstStrike = true
        }
        
        // ① コスト計算
        let cost = equipmentCost(of: card)
        if cost > 0 {
            // GOLD 支払い
            guard tryPay(cost, by: user) else {
                if user == 0 {
                    battleResult = "G不足（必要: \(cost)）"
                }
                return false
            }
        }
        
        if isAttacker && card.id == "sp-poisonFang" {
            willPoisonDefender = true
        }

        // ③ 効果適用
        if isAttacker {
            apply(card: card, to: &left)
            battleLeft = left
        } else {
            apply(card: card, to: &right)
            battleRight = right
        }

        return true
    }
    
    private func apply(card: Card, to target: inout BattleCombatant) {
        switch card.id { 
        case "sp-hardFang":
            target.itemPower += 10
        case "sp-sharpFang":
            target.itemPower += 20
        case "sp-bigScale":
            target.itemDurability += 10
        case "sp-hardScale":
            target.itemDurability += 20
        case "sp-poisonFang":
            break
        default:
            break
        }
    }
    
    func finishBattleItemSelection(_ card: Card, for pid: Int) {
        // ★ 支払い＋効果適用に成功した場合だけ手札から削除
        if applyBattleEquipment(card, by: pid) {
            consumeFromHand(card, for: pid)
            playBattleSpellCastEffect {
                self.isBattleItemSelectionPhase = false
            }
        }
    }

    private func removeCardFromHand(_ card: Card, for pid: Int) -> Int? {
        guard hands.indices.contains(pid),
              let index = hands[pid].firstIndex(of: card) else { return nil }
        hands[pid].remove(at: index)
        return index
    }

    func consumeFromHand(_ card: Card, for pid: Int) {
        _ = removeCardFromHand(card, for: pid)
    }

    @discardableResult
    private func beginPendingSpellUsage(card: Card, owner: Int, cost: Int) -> Bool {
        guard pendingSpellCard == nil else { return false }
        guard let removedIndex = removeCardFromHand(card, for: owner) else { return false }
        pendingSpellCard = card
        pendingSpellOwner = owner
        pendingSpellHandIndex = removedIndex
        pendingSpellCost = cost
        return true
    }

    private func restorePendingSpellUsage() {
        guard let card = pendingSpellCard,
              let owner = pendingSpellOwner,
              hands.indices.contains(owner) else {
            clearPendingSpellTracking()
            return
        }

        let maxIndex = hands[owner].count
        let insertIndex = min(max(pendingSpellHandIndex ?? maxIndex, 0), maxIndex)
        hands[owner].insert(card, at: insertIndex)
        clearPendingSpellTracking()
    }

    private func clearPendingSpellTracking() {
        pendingSpellCard = nil
        pendingSpellOwner = nil
        pendingSpellHandIndex = nil
        pendingSpellCost = 0
    }

    @discardableResult
    private func finalizePendingSpellUsage() -> Bool {
        guard let owner = pendingSpellOwner else { return true }
        let cost = pendingSpellCost
        if cost > 0 && !tryPay(cost, by: owner) {
            if owner == 0 {
                pushCenterMessage("GOLDが足りません（必要: \(cost)）")
            }
            restorePendingSpellUsage()
            return false
        }
        clearPendingSpellTracking()
        return true
    }

    private func paySpellCostIfNeeded(_ cost: Int, by pid: Int) -> Bool {
        guard cost > 0 else { return true }
        guard tryPay(cost, by: pid) else {
            if pid == 0 {
                pushCenterMessage("GOLDが足りません（必要: \(cost)）")
            }
            return false
        }
        return true
    }

    func isBattleOnlySpell(_ card: Card) -> Bool {
        guard card.kind == .spell,
              let effect = card.spell else { return false }
        switch effect {
        case .buffPower, .buffDefense, .firstStrike, .poison, .reflectSkill:
            return true
        default:
            return false
        }
    }
    
    // === 追加: 設置可否チェック ===
    func canPlaceCreature(at index: Int) -> Bool {
        return !isSpecialNode(index)
    }

    /// クリーチャー移動の移動先選択を表示
    func actionMoveCreatureFromSpecialNode() {
        if let t = focusTile,
           owner.indices.contains(t), owner[t] == turn,
           level.indices.contains(t), level[t] >= 1,
           creatureSymbol.indices.contains(t), creatureSymbol[t] != nil {
            activeSpecialSheet = .moveFrom(tile: t)
            return
        }
        specialPending = .pickMoveSource
        pushCenterMessage("移動するデジレプを選択")
    }

    /// スペル購入シートを表示
    func actionPurchaseSkillOnSpecialNode() {
        activeSpecialSheet = .buySpell
    }
    
    func showDiceGlitch(number: Int) {
        diceGlitchNumber = number
        isShowingDiceGlitch = true
        SoundManager.shared.playDiceFixSE()
    }

    private func playBattleSpellCastEffect(completion: @escaping () -> Void) {
        battleSpellEffectID = UUID()
        isShowingBattleSpellEffect = true
        SoundManager.shared.playBattleSpellSound()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            self.isShowingBattleSpellEffect = false
            completion()
        }
    }

// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　NPC行動ロジック
// MARK: ---------------------------------------------------------------------------

    @MainActor
    private func runCpuAuto() async {
        try? await Task.sleep(nanoseconds: 500_000_000)

        // 捨て必要ならランダム捨て
        if hands[1].count > 4, let c = hands[1].randomElement() { discard(c, for: 1) }

        // ロール前にスペル使用
        cpuUseRandomDiceFixSpellIfAvailable()
        cpuUseDeleteHandIfAvailable()

        let r: Int
        if let forced = nextForcedRoll[1] {
            r = forced
        } else {
            if doubleDice[1] {
                let d1 = Int.random(in: 1...6)
                let d2 = Int.random(in: 1...6)
                r = d1 + d2
            } else {
                r = Int.random(in: 1...6)
            }
        }
        lastRoll = r
        doubleDice[1] = false
        nextForcedRoll[1] = nil
        forceRollToOneFor[1] = false
        stepsLeft = lastRoll

        // 分岐の事前選択（必要なら）
        if players[1].pos == CROSS_NODE, stepsLeft > 0 {
            let choices: [Int]
            if passedCP2.indices.contains(1), passedCP2[1] == false {
                choices = [27, 28]
            } else if passedCP2.indices.contains(1), passedCP2[1] == true {
                choices = [3, 5]
            } else {
                choices = CROSS_CHOICES
            }
            if let choice = choices.randomElement() { applyBranchChoice(choice) }
        }

        phase = .moving
        // ★ ここで“本当に”移動完了を待つ
        await continueMoveAnimated()

        let t = players[1].pos

        // ★ 戦闘が発生している場合は、この先のレベルアップ・設置・ターン終了は
        //   BattleOverlay の onFinished → finishBattle 側で行う
        if isAwaitingBattleResult || showBattleOverlay {
            return
        }

        // 自軍タイルならLv+1（可能なら）
        if owner.indices.contains(t), owner[t] == 1,
           level.indices.contains(t), level[t] >= 1, level[t] < 5 {
            let cur = level[t], nextLv = cur + 1
            if players[1].gold >= (levelUpCost[nextLv] ?? .max) {
                confirmLevelUp(tile: t, to: nextLv)
            }
        }

        if owner[t] == nil,
           canPlaceCreature(at: t),
           let creature = cpuPickCreatureForTile(t) {

            if paySummonCostIfNeeded(for: creature, by: 1),
               placeCreature(from: creature, at: t, by: 1) {
                consumeFromHand(creature, for: 1)
            }
        }

        try? await Task.sleep(nanoseconds: 2_000_000_000)
        endTurn()
    }
    
    private func cpuUseRandomDiceFixSpellIfAvailable() {
        // すでに強制出目 or ダブルダイスが決まっていたら何もしない
        if nextForcedRoll[1] != nil || doubleDice[1] { return }

        enum Candidate {
            case fix(idx: Int, n: Int)
            case double(idx: Int)
        }

        let candidates: [Candidate] = hands[1].enumerated().compactMap { (i, c) in
            guard c.kind == .spell, let spell = c.spell else { return nil }

            switch spell {
            case let .fixNextRoll(n) where (1...6).contains(n):
                return .fix(idx: i, n: n)
            case .doubleDice:
                return .double(idx: i)
            default:
                return nil
            }
        }

        guard let pick = candidates.randomElement() else { return }

        switch pick {
        case let .fix(idx, n):
            _ = hands[1].remove(at: idx)
            nextForcedRoll[1] = n

        case let .double(idx):
            _ = hands[1].remove(at: idx)
            doubleDice[1] = true
        }
    }
    
    private func cpuUseDeleteHandIfAvailable() {
        let npcId = 1          // CPU
        let playerId = 0       // プレイヤー

        // プレイヤーの手札がないなら何もできない
        guard hands.indices.contains(playerId),
              !hands[playerId].isEmpty else { return }

        // CPUの手札から「discardOpponentCards」のスペルを探す
        guard hands.indices.contains(npcId) else { return }

        guard let idx = hands[npcId].firstIndex(where: { card in
            guard card.kind == .spell,
                  let effect = card.spell else { return false }

            // sp-deleteHand: .discardOpponentCards(1) のみ対象
            switch effect {
            case .discardOpponentCards:
                // GOLD が足りているかもこの場でチェック
                let c = spellCost(of: card)
                return c <= (players.indices.contains(npcId) ? players[npcId].gold : 0)
            default:
                return false
            }
        }) else {
            return
        }

        let spellCard = hands[npcId][idx]
        let cost = spellCost(of: spellCard)

        // GOLD 支払い（足りなければ使わない）
        if cost > 0 {
            guard tryPay(cost, by: npcId) else { return }
        }

        // スペルカード自体をCPU手札から削除
        hands[npcId].remove(at: idx)

        // プレイヤー手札からランダムに1枚削除
        guard !hands[playerId].isEmpty else { return }
        let removeIdx = Int.random(in: 0..<hands[playerId].count)
        let removedCard = hands[playerId].remove(at: removeIdx)

        // オーバーレイ表示用に保存
        deletePreviewCard = removedCard
        deletingTargetPlayer = playerId
        isSelectingOpponentHandToDelete = false
        pendingDeleteHandIndex = nil

        // 中央メッセージ
        pushCenterMessage("NPCがあなたの手札を1枚削除")
    }
    
    private func cpuPickCreatureForTile(_ tile: Int) -> Card? {
        // 1) 手札からクリーチャーだけを抽出
        let creatures = hands[1].filter { $0.kind == .creature }
        guard !creatures.isEmpty else { return nil }

        // 2) CPUの所持ゴールド（高すぎるカードは避ける用）
        let gold = players[1].gold

        // 3) クリーチャーの stats コスト取得用ヘルパー
        func stats(for card: Card) -> CreatureStats {
            card.stats ?? CreatureStats.defaultLizard
        }

        // 4) まず「払えるカード」だけに絞る（全部高すぎるなら妥協して全カード対象）
        let affordable = creatures.filter { stats(for: $0).cost <= gold }
        let pool = affordable.isEmpty ? creatures : affordable
        let attr = tileAttribute(of: tile)

        // 4) 属性ごとのスコア
        func score(for card: Card) -> Int {
            let s = stats(for: card)
            switch attr {
            case .normal:
                // ノーマルマス → ランダムで OK
                return Int.random(in: 0..<1000)
            case .dry:
                return s.resistDry
            case .water:
                return s.resistWater
            case .heat:
                return s.resistHeat
            case .cold:
                return s.resistCold
            }
        }

        // 5) スコア最大のカードを選ぶ（同点ならどれか1枚）
        return pool.max { score(for: $0) < score(for: $1) }
    }

    private func bestAttackerCard(in hand: [Card], for attr: TileAttribute) -> Card? {
        // 火力 = power*2 + resist(attr)*4 を最大化
        hand
            .filter { $0.kind == .creature }
            .max(by: { (lhs, rhs) in
                let ls = lhs.stats ?? .defaultLizard
                let rs = rhs.stats ?? .defaultLizard
                let lScore = ls.power * 2 + resistValue(of: ls, for: attr) * 4
                let rScore = rs.power * 2 + resistValue(of: rs, for: attr) * 4
                return lScore < rScore
            })
    }

    private func bestDefenderCard(in hand: [Card], for attr: TileAttribute) -> Card? {
        // 防御 = durability + resist(attr) を最大化
        hand
            .filter { $0.kind == .creature }
            .max(by: { (lhs, rhs) in
                let ls = lhs.stats ?? .defaultLizard
                let rs = rhs.stats ?? .defaultLizard
                let lScore = ls.durability + resistValue(of: ls, for: attr)
                let rScore = rs.durability + resistValue(of: rs, for: attr)
                return lScore < rScore
            })
    }
    
    // ▼ CPU：最小売却の自動実行（合計が赤字額以上になる最小合計を選ぶ）
    private func autoLiquidateCPU(target deficit: Int) {
        let p = 1
        let myTiles: [Int] = owner.enumerated().compactMap { (i, o) in (o == p) ? i : nil }
        let values: [(idx: Int, val: Int)] = myTiles.map { ($0, saleValue(for: $0)) }.filter { $0.val > 0 }
        guard !values.isEmpty else { return } // 売れる土地が無い → 別途ゲームオーバー等の検討箇所

        // 簡易DP：sums[合計]=タイル配列、から「合計>=deficitの最小」を選ぶ
        var sums: [Int: [Int]] = [0: []]
        let cap = values.map(\.val).reduce(0, +)
        let limit = max(0, deficit)
        for (idx, val) in values {
            let snap = sums
            for (s, arr) in snap {
                let ns = s + val
                if ns > cap { continue }
                if sums[ns] == nil || (sums[ns]!.count > arr.count + 1) {
                    sums[ns] = arr + [idx]
                }
            }
        }
        if let bestSum = sums.keys.filter({ $0 >= limit }).min(),
           let sellSet = sums[bestSum] {
            for t in sellSet { performSell(tile: t, for: p) }
        } else {
            // どう組んでも足りない → すべて売却（フォールバック）
            for t in values.sorted(by: { $0.val < $1.val }).map(\.idx) { performSell(tile: t, for: p) }
        }
    }

// MARK: ------------------------------------------------------------------------------------------------------
// MARK:       マス管理
// MARK: ------------------------------------------------------------------------------------------------------
    
    // 自軍マスメニューを開く／閉じるヘルパー
    func openMyTileMenu(at index: Int) {
        myTileIndex = index
        showMyTile = true

        // 他メニューは閉じておくと干渉しにくい
        showCreatureMenu = false
        showSpecialMenu = false
    }
    
    func closeMyTileMenu() {
        myTileIndex = nil
        showMyTile = false
    }

    // ★ レベルアップ・クリーチャー交換のアクションの入り口
    func actionLevelUpOnMyTile() {
        // まずは CreatureMenu 優先で見る
        let target = creatureMenuTile ?? myTileIndex
        guard let t = target else { return }

        // メニューは閉じる
        showCreatureMenu = false
        closeMyTileMenu()

        // レベルアップ用シートを表示
        activeSpecialSheet = .levelUp(tile: t)
    }

    func actionChangeCreatureOnMyTile() {
        guard let t = myTileIndex else { return }
        self.creatureMenuTile = t
        self.showCreatureMenu = true
        // ついでに自軍マスメニューは閉じてしまう
        closeMyTileMenu()
    }
    
    private func buildFixedTerrain() -> [TileTerrain] {
        // 既定は field（ノーマル）
        var arr = Array(
            repeating: TileTerrain(imageName: "field", attribute: .normal),
            count: tileCount
        )

        // 1始まり → 配列index（0始まり）に変換して代入するヘルパ
        func setRange(_ startTile: Int, _ endTile: Int, image: String, attr: TileAttribute) {
            let s = max(1, startTile)
            let e = min(tileCount, endTile)
            guard s <= e else { return }
            for t in s...e {
                let i = t - 1   // 1始まり → 0始まり
                arr[i] = TileTerrain(imageName: image, attribute: attr)
            }
        }

        // 指定の固定割り当て（タイル番号は 1..31）
        setRange( 2,  4, image: "field",  attr: .normal) // 2〜4
        setRange( 6,  9, image: "desert", attr: .dry)    // 6〜9
        setRange(10, 13, image: "water",  attr: .water)  // 10〜13
        setRange(14, 16, image: "field",  attr: .normal) // 14〜16
        setRange(17, 20, image: "fire",   attr: .heat)   // 17〜20
        setRange(22, 25, image: "snow",   attr: .cold)   // 22〜25
        setRange(26, 31, image: "field",  attr: .normal) // 26〜31

        // 指定が無い 1,5,21（＝チェックポイント）は既定の field のまま
        return arr
    }

    // 料金計算（レベル基礎 × セットボーナス）
    func toll(at tile: Int) -> Int {
        if devastatedTiles.contains(tile) {
            return 0
        }
        
        guard level.indices.contains(tile) else { return 0 }
        let lv = level[tile]

        // 基礎額（あなたの元の係数に揃えています）
        let base: Int
        switch lv {
        case ..<1: base = 0
        case 1:    base = 30
        case 2:    base = 60
        case 3:    base = 120
        case 4:    base = 240
        case 5:    base = 480
        default:   base = 30 * (16 + lv)   // 既存の拡張ロジックを踏襲
        }

        // オーナー不在なら倍率なし
        guard owner.indices.contains(tile), let pid = owner[tile] else {
            return base
        }

        // 同属性セット数 → 倍率
        let attr = attribute(of: tile)
        let n = sameAttributeCount(for: pid, attr: attr)
        let mult = setBonusMultiplier(for: n)

        var value = Int((Double(base) * mult).rounded())
        
        if harvestedTiles.contains(tile) {
            value *= 2
        }
        
        return value

    }
    
    // 属性取得（未設定は .normal 扱い）
    private func attribute(of index: Int) -> TileAttribute {
        guard terrain.indices.contains(index) else { return .normal }
        return terrain[index].attribute
    }

    // 指定プレイヤーが所有する「同じ属性」の土地数
    private func sameAttributeCount(for pid: Int, attr: TileAttribute) -> Int {
        var count = 0
        for i in 0..<tileCount {
            if owner.indices.contains(i),
               owner[i] == pid,
               attribute(of: i) == attr {
                count += 1
            }
        }
        return count
    }

    // セットボーナス倍率（1: 1.0, 2: 1.2, 3: 1.3, 4以上: 1.5）
    private func setBonusMultiplier(for sameAttrCount: Int) -> Double {
        switch sameAttrCount {
        case 2:      return 1.2
        case 3:      return 1.5
        case 4:      return 1.8
        case 5...:   return 2.0
        default:     return 1.0
        }
    }
    
    @discardableResult
    func placeCreature(from card: Card, at tile: Int, by pid: Int) -> Bool {
        guard canPlaceCreature(at: tile) else { return false }
        
        let s = card.stats ?? CreatureStats.defaultLizard
        
        self.spellEffectTile = tile
        self.spellEffectKind = .place
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if self?.spellEffectTile == tile {
                self?.spellEffectTile = nil
            }
        }

        owner[tile] = pid
        level[tile] = max(level[tile], 1)
        creatureSymbol[tile] = card.symbol
        hpMax[tile] = s.hpMax
        hp[tile] = s.hpMax
        aff[tile]  = s.affection
        pow[tile]  = s.power
        dur[tile]  = s.durability
        rDry[tile] = s.resistDry
        rWat[tile] = s.resistWater
        rHot[tile] = s.resistHeat
        rCold[tile] = s.resistCold
        cost[tile]  = s.cost
        if poisonedTiles.indices.contains(tile) {
            poisonedTiles[tile] = false
        }
        hp = hp
        creatureOnTile[tile] = Creature(
            id: UUID().uuidString,
            owner: pid,
            imageName: card.symbol,
            stats: s,
            hp: s.hpMax
        )
        toll[tile] = toll(at: tile)
        return true
    }
    
    /// マスの属性を返す
    private func attributeAt(tile: Int) -> TileAttribute {
        guard terrain.indices.contains(tile) else { return .normal }
        return terrain[tile].attribute
    }

    private func tileStatusDescription(for tile: Int) -> String {
        var statuses: [String] = []
        if poisonedTiles.indices.contains(tile), poisonedTiles[tile] {
            statuses.append("毒")
        }
        if devastatedTiles.contains(tile) {
            statuses.append("荒廃")
        }
        if harvestedTiles.contains(tile) {
            statuses.append("豊作")
        }
        if statuses.isEmpty {
            return "なし"
        }
        return statuses.joined(separator: " / ")
    }

    private func tileHasCleanseStatus(_ tile: Int) -> Bool {
        if poisonedTiles.indices.contains(tile), poisonedTiles[tile] { return true }
        if devastatedTiles.contains(tile) { return true }
        if harvestedTiles.contains(tile) { return true }
        return false
    }
    
    /// レベルアップ候補を表示
    func actionLevelUpOnSpecialNode() {
        // 今立っているマス（focusTile）で即実行できるならそのまま
        if let t = focusTile,
           owner.indices.contains(t), owner[t] == turn,
            level.indices.contains(t), level[t] >= 1 {
            activeSpecialSheet = .levelUp(tile: t)
            return
        }
        // それ以外は「選ばせる」モードへ
        specialPending = .pickLevelUpSource
        pushCenterMessage("レベルUPする土地を選択")
    }
    
    func canSeeFullStats(of creature: Creature, viewer: Int) -> Bool {
        guard (0..<players.count).contains(viewer) else { return false }
        if creature.owner == viewer { return true }
        guard clairvoyanceRevealedCreatureIDs.indices.contains(viewer) else { return false }
        return clairvoyanceRevealedCreatureIDs[viewer].contains(creature.id)
    }

    private func performClairvoyance(for pid: Int) {
        guard clairvoyanceRevealedCreatureIDs.indices.contains(pid) else { return }
        let enemyIDs = creatureOnTile.values
            .filter { $0.owner != pid }
            .map { $0.id }
        var updated = clairvoyanceRevealedCreatureIDs[pid]
        let beforeCount = updated.count
        enemyIDs.forEach { updated.insert($0) }
        clairvoyanceRevealedCreatureIDs[pid] = updated

        if enemyIDs.isEmpty {
            if pid == 0 {
                pushCenterMessage("透視できる敵クリーチャーがいません")
            } else {
                pushCenterMessage("CPUは透視を使用しましたが対象がいません")
            }
        } else if updated.count > beforeCount {
            if pid == 0 {
                pushCenterMessage("敵クリーチャーのステータスを解析しました")
            } else {
                pushCenterMessage("CPUが透視を使用しました")
            }
        } else {
            if pid == 0 {
                pushCenterMessage("新たに解析できる敵クリーチャーはいません")
            } else {
                pushCenterMessage("CPUが透視を使用しました（新情報なし）")
            }
        }

        triggerBoardWideEffect(.clairvoyance)
    }

    @discardableResult
    private func applyClairvoyanceSpell(for pid: Int, cost: Int) -> Bool {
        guard paySpellCostIfNeeded(cost, by: pid) else { return false }
        performClairvoyance(for: pid)
        return true
    }
    
    // マップ・クリーチャー情報を混ぜた検査VMを作る
    func makeInspectView(for tile: Int, viewer: Int) -> CreatureInspectView? {
        // 個体が未登録なら配列ベースの旧データから推測するフォールバック
        var creature: Creature?
        if let c = creatureOnTile[tile] { creature = c }
        else if owner.indices.contains(tile), let own = owner[tile] {
            // 旧配列から最小限再構築（画像はシンボル名を仮置き）
            if hpMax.indices.contains(tile) {
                let stats = CreatureStats(
                    hpMax: hpMax[tile],
                    affection: aff[tile],
                    power: pow[tile],
                    durability: dur[tile],
                    resistDry: rDry[tile],
                    resistWater: rWat[tile],
                    resistHeat: rHot[tile],
                    resistCold: rCold[tile],
                    cost: (cost.indices.contains(tile) ? cost[tile] : 1)
                )
                let img = creatureSymbol.indices.contains(tile) ? (creatureSymbol[tile] ?? "lizard.fill") : "lizard.fill"
                creature = Creature(id: "legacy-\(tile)", owner: own, imageName: img, stats: stats, hp: hp[tile])
            }
        }
        guard let c = creature else { return nil }

        // 地形の安全参照（未初期化ならデフォルト）
        let mapImg: String
        let mapAttrJP: String
        if terrain.indices.contains(tile) {
            mapImg = terrain[tile].imageName
            // top-level TileAttribute を日本語にマップ
            switch terrain[tile].attribute {
            case .normal: mapAttrJP = "ノーマル"
            case .dry:    mapAttrJP = "砂地"
            case .water:  mapAttrJP = "水辺"
            case .heat:   mapAttrJP = "火山"
            case .cold:   mapAttrJP = "雪原"
            }
        } else {
            mapImg = "field"
            mapAttrJP = "ノーマル"
        }

        let seeAll = canSeeFullStats(of: c, viewer: viewer)
        func show(_ v: Int) -> String { String(v) }
        func mask(_ v: Int) -> String { seeAll ? show(v) : "不明" }

        let tileLevelValue = level.indices.contains(tile) ? level[tile] : 0
        let statusText = tileStatusDescription(for: tile)

        return CreatureInspectView(
            tileIndex: tile,
            mapImageName: mapImg,
            mapAttribute: mapAttrJP,
            tileLevel: tileLevelValue,
            tileStatus: statusText,
            owner: c.owner,
            imageName: c.imageName,
            hpText: "\(c.hp) / \(c.stats.hpMax)",
            affection: seeAll ? show(c.stats.affection) : "不明",
            power:     seeAll ? show(c.stats.power)     : "不明",
            durability:seeAll ? show(c.stats.durability): "不明",
            dryRes:    mask(c.stats.resistDry),
            waterRes:  mask(c.stats.resistWater),
            heatRes:   mask(c.stats.resistHeat),
            coldRes:   mask(c.stats.resistCold)
        )
    }
    
    // タイル上のクリーチャー情報をクリアする共通メソッド
    func clearCreatureInfo(at tile: Int,
                           clearOwnerAndLevel: Bool = false,
                           resetToll: Bool = false) {
        guard (0..<tileCount).contains(tile) else { return }

        // クリーチャー関連ステータスをクリア
        if creatureSymbol.indices.contains(tile) { creatureSymbol[tile] = nil }
        if hp.indices.contains(tile)           { hp[tile] = 0 }
        if hpMax.indices.contains(tile)        { hpMax[tile] = 0 }
        if aff.indices.contains(tile)          { aff[tile] = 0 }
        if pow.indices.contains(tile)          { pow[tile] = 0 }
        if dur.indices.contains(tile)          { dur[tile] = 0 }
        if rDry.indices.contains(tile)         { rDry[tile] = 0 }
        if rWat.indices.contains(tile)         { rWat[tile] = 0 }
        if rHot.indices.contains(tile)         { rHot[tile] = 0 }
        if rCold.indices.contains(tile)        { rCold[tile] = 0 }
        if cost.indices.contains(tile)         { cost[tile] = 0 }
        if poisonedTiles.indices.contains(tile) {
            poisonedTiles[tile] = false
        }

        // Creature辞書からも削除
        creatureOnTile.removeValue(forKey: tile)

        // 土地自体も空にしたい場合
        if clearOwnerAndLevel {
            if owner.indices.contains(tile) { owner[tile] = nil }
            if level.indices.contains(tile) { level[tile] = 0 }
        }

        // 通行料リセット
        if resetToll, toll.indices.contains(tile) {
            toll[tile] = 0
        }

        // View更新用
        hp = hp
        objectWillChange.send()
    }
    
    // タイルタップ時ハンドラ（クリーチャーがいないタイルは無視）
    func tapTileForInspect(_ index: Int) {
        // === ここから追加: sp-elixir のターゲット選択 ===
        if isSelectingFullHealTarget {
            // 候補外のマスは無視
            guard fullHealCandidateTiles.contains(index) else { return }
            pendingFullHealTile = index   // 確認ウインドウ表示用
            return
        }
        // === sp-decay のターゲット選択 ===
        if isSelectingLandLevelChangeTarget {
            // レベルダウン候補外のマスは無視
            guard landLevelChangeCandidateTiles.contains(index) else { return }
            pendingLandLevelChangeTile = index   // レベルダウン確認ウインドウ表示用
            return
        }
        // === sp-devastation のターゲット選択 ===
        if isSelectingLandTollZeroTarget {
            guard landTollZeroCandidateTiles.contains(index) else { return }
            pendingLandTollZeroTile = index   // 通行量0確認ウインドウ表示用
            return
        }
        // === sp-harvest のターゲット選択（通行量2倍） ===
        if isSelectingLandTollDoubleTarget {
            guard landTollDoubleCandidateTiles.contains(index) else { return }
            pendingLandTollDoubleTile = index   // 通行量2倍確認ウインドウ表示用
            return
        }
        if isSelectingPoisonTarget {
            guard poisonCandidateTiles.contains(index) else { return }
            pendingPoisonTile = index
            return
        }
        if isSelectingCleanseTarget {
            guard cleanseCandidateTiles.contains(index) else { return }
            pendingCleanseTile = index
            return
        }
        if isSelectingDamageTarget {
            guard damageCandidateTiles.contains(index) else { return }
            pendingDamageTile = index
            return
        }
        // ← 先に特別アクション選択モードを優先処理
        if let pending = specialPending {
            switch pending {
            case .pickLevelUpSource:
                // 自分の占有＆設置済(>=1) ならOK
                if owner.indices.contains(index), owner[index] == turn,
                   level.indices.contains(index), level[index] >= 1 {
                    activeSpecialSheet = .levelUp(tile: index)
                    specialPending = nil
                    battleResult = nil // さっきの案内を消す
                }
                return

            case .pickMoveSource:
                // 自分の占有＆クリーチャーがいるマス
                if owner.indices.contains(index), owner[index] == turn,
                   level.indices.contains(index), level[index] >= 1,
                   creatureSymbol.indices.contains(index), creatureSymbol[index] != nil {
                    activeSpecialSheet = .moveFrom(tile: index)
                    specialPending = nil
                    battleResult = nil
                }
                return
            }
        }

        // ↑選択モードではない通常時：既存のInspect動作
        if creatureOnTile[index] == nil, (owner.indices.contains(index) ? owner[index] : nil) == nil {
            return
        }
        inspectTarget = index
    }

    func closeInspect() { inspectTarget = nil }
    
    private func isCheckpoint(_ index: Int) -> Bool {
        return index == CP1_NODE || index == CP2_NODE
    }
    
    private func ownedTileCount(of pid: Int) -> Int {
        owner.reduce(0) { $0 + (($1 == pid) ? 1 : 0) }
    }

    // 300 + (自分の設置マス数 × 30)
    private func checkpointReward(for pid: Int) -> Int {
        300 + ownedTileCount(of: pid) * 30
    }
    
    func totalAssets(for pid: Int) -> Int {
        let gold = players.indices.contains(pid) ? players[pid].gold : 0
        var sumToll = 0
        for i in 0..<tileCount {
            if owner.indices.contains(i), owner[i] == pid {
                // 現在レベルから都度算出（配列tollを参照せず最新を反映）
                sumToll += toll(at: i)
            }
        }
        return gold + sumToll
    }
    
    // 売却額（＝現行の通行料を売値にする）
    func saleValue(for tile: Int) -> Int {
        return max(0, toll(at: tile))
    }
    
    func confirmSellTile() {
        guard let t = sellConfirmTile else { return }
        performSell(tile: t, for: 0)
        sellConfirmTile = nil
        if players[0].gold < 0 {
            debtAmount = -players[0].gold
        } else {
            isForcedSaleMode = false
            debtAmount = 0
        }
    }

    func cancelSellTile() {
        sellConfirmTile = nil
    }

    // ▼ 売却の実処理（共通）: 所有解除・レベル/通行料/シンボル初期化
    private func performSell(tile idx: Int, for player: Int) {
        let v = saleValue(for: idx)
        if players.indices.contains(player) {
            players[player].gold += v
        }
        clearCreatureInfo(at: idx,
                          clearOwnerAndLevel: true,
                          resetToll: true)
    }
    
    /// レベルアップ確定
    func confirmLevelUp(tile: Int, to newLevel: Int) {
        guard owner.indices.contains(tile), owner[tile] == turn else { return }
        guard level.indices.contains(tile) else { return }
        let cur = level[tile]
        guard newLevel >= 2, newLevel <= 5, newLevel > cur else { return }
        guard let cost = levelUpCost[newLevel] else { return }

        if players[turn][keyPath: goldRef] < cost { return } // 足りない

        addGold(-cost, to: turn)
        level[tile] = newLevel

        // 通行料などをレベル依存で再計算したい場合
        if toll.indices.contains(tile) {
            toll[tile] = toll(at: tile)
        }

        // ログやフローティングメッセージ
        pushCenterMessage("土地を Lv\(newLevel) に強化 -\(cost)G")

        activeSpecialSheet = nil
        objectWillChange.send()
    }
    
    /// クリーチャー移動確定
    func confirmMoveCreature(from: Int, to: Int) {
        guard owner.indices.contains(from), owner[from] == turn else { return }
        guard owner.indices.contains(to), owner[to] == nil else { return }
        guard !isSpecialNode(to) else { return } // 特別マス禁止（必要なら外せます）

        guard creatureSymbol.indices.contains(from), let sym = creatureSymbol[from] else { return }

        // 付随ステータス一式コピー
        let fromLv   = level.indices.contains(from) ? level[from] : 0
        let fromHp   = hp.indices.contains(from) ? hp[from] : 0
        let fromHpM  = hpMax.indices.contains(from) ? hpMax[from] : 0

        owner[to] = owner[from]
        level[to] = fromLv
        creatureSymbol[to] = sym
        hp[to] = fromHp
        hpMax[to] = fromHpM
        // 表示用tollは都度再計算に統一（下 §5 参照）
        toll[to] = toll(at: to)

        // creatureOnTile も移設
        if let c = creatureOnTile[from] {
            creatureOnTile[to] = c
            creatureOnTile.removeValue(forKey: from)
        }

        // 元をクリア（更地にする）
        clearCreatureInfo(at: from,
                          clearOwnerAndLevel: true,
                          resetToll: true)

        pushCenterMessage("デジレプを移動")
        activeSpecialSheet = nil
        objectWillChange.send()
    }
    
    func canSwapCreature(withHandIndex idx: Int) -> Bool {
        guard let t = creatureMenuTile else { return false }
        guard owner.indices.contains(t), owner[t] == turn else { return false }
        guard hands.indices.contains(turn),
              hands[turn].indices.contains(idx),
              hands[turn][idx].kind == .creature else { return false }
        let costNeed = hands[turn][idx].stats?.cost ?? 0
        return players[turn].gold >= costNeed
    }

    @discardableResult
    func swapCreature(withHandIndex idx: Int) -> Bool {
        guard let t = creatureMenuTile else { return false }
        guard canSwapCreature(withHandIndex: idx) else { return false }

        // 支払い
        let newCard = hands[turn][idx]
        let price = max(0, newCard.stats?.cost ?? 0)
        guard tryPay(price, by: turn) else { return false }

        // 既存カードを“手札に戻す”
        if let oldSym = creatureSymbol[t] {
            // タイル上の配列からステータスを復元
            let oldStats = CreatureStats(
                hpMax: hpMax[t],
                affection: aff[t],
                power: pow[t],
                durability: dur[t],
                resistDry: rDry[t],
                resistWater: rWat[t],
                resistHeat: rHot[t],
                resistCold: rCold[t],
                cost: cost[t]
            )

            // Card は id が必須なので、新規UUIDを振る
            let oldCard = Card(
                id: UUID().uuidString,
                kind: .creature,
                name: oldSym,
                symbol: oldSym,
                stats: oldStats,
                spell: nil
            )
            hands[turn].append(oldCard)
        }

        // 新カードで上書き（HPは全快で置き直し）
        let s = newCard.stats ?? .defaultLizard
        creatureSymbol[t] = newCard.symbol
        hpMax[t] = s.hpMax
        hp[t] = s.hpMax
        aff[t] = s.affection
        pow[t] = s.power
        dur[t] = s.durability
        rDry[t] = s.resistDry
        rWat[t] = s.resistWater
        rHot[t] = s.resistHeat
        rCold[t] = s.resistCold
        cost[t] = s.cost
        toll[t] = toll(at: t)
        creatureOnTile[t] = Creature(id: UUID().uuidString, owner: turn, imageName: newCard.symbol, stats: s, hp: s.hpMax)

        // 新カードを手札から除去
        hands[turn].remove(at: idx)

        // 見た目更新
        hp = hp
        return true
    }
    
    private func cpuUseEquipSkillIfAvailable() {
        let npcId = 1
        let gold = players.indices.contains(npcId) ? players[npcId].gold : 0

        // コストを払える「装備スキルカード」だけを対象にする
        guard let index = hands[npcId].firstIndex(where: {
            isEquipSkillCard($0) && equipmentCost(of: $0) <= gold
        }) else {
            return
        }

        let equipCard = hands[npcId][index]

        // 支払い＋効果適用成功時のみ手札から削除
        if applyBattleEquipment(equipCard, by: npcId) {
            hands[npcId].remove(at: index)
        }
    }
    
    private func isEquipSkillCard(_ card: Card) -> Bool {
        // spell 以外は装備スキルではない
        guard card.kind == .spell,
              let effect = card.spell else {
            return false
        }

        switch effect {
        case .buffPower,
             .buffDefense,
             .firstStrike,
             .poison,
             .reflectSkill:
            return true

        default:
            return false
        }
    }

// MARK: -----------------------------------------------------------------------------
// MARK: - 戦闘管理
// MARK: -----------------------------------------------------------------------------
    
    private func tryPay(_ amount: Int, by pid: Int) -> Bool {
        guard amount > 0 else { return true }
        guard players.indices.contains(pid) else { return false }
        if players[pid].gold >= amount {
            players[pid].gold -= amount
            return true
        } else {
            return false
        }
    }

    func hpRatio(_ tile: Int) -> CGFloat? {
        guard owner.indices.contains(tile),
              owner[tile] != nil,
              hpMax[tile] > 0
        else { return nil }
        return CGFloat(hp[tile]) / CGFloat(hpMax[tile])
    }
    
    func chooseBattle() {
        guard landedOnOpponentTileIndex != nil else { return }
        guard hasSummonableCreature(for: turn) else {
            payTollAndEndChoice()
            return
        }
        expectBattleCardSelection = true
        canEndTurn = true
        showLogOverlay = false
    }

    func payTollAndEndChoice() {
        guard let t = landedOnOpponentTileIndex, let own = owner[t] else { return }
        transferToll(from: turn, to: own, tile: t)
        battleResult = (turn == 1)
            ? "通行料を奪った"      // CPUが支払ってあなたが受け取り
            : "通行料を奪われた"   // あなたが支払い
        landedOnOpponentTileIndex = nil
        expectBattleCardSelection = false
        canEndTurn = true
    }
    
    private func highestResistAt(tile: Int) -> Int {
        max(rDry[tile], rWat[tile], rHot[tile], rCold[tile])
    }
    
    private func resistValue(of stats: CreatureStats, for attr: TileAttribute) -> Int {
        switch attr {
        case .normal:
            return stats.highestResist
        case .dry:
            return stats.resistDry
        case .water:
            return stats.resistWater
        case .heat:
            return stats.resistHeat
        case .cold:
            return stats.resistCold
        }
    }

    /// 守備側（タイル上のクリーチャー）の抵抗値を、マス属性に合わせて取得
    private func defenderResistAt(tile: Int, for attr: TileAttribute) -> Int {
        if let defCard = creatureOnTile[tile] {
            // 守備側カードのステータスから取得（無ければ既定トカゲ）
            let s = defCard.stats
            return resistValue(of: s, for: attr)
        } else {
            // クリーチャー不在などのフォールバック（従来の最高抵抗を使用）
            return highestResistAt(tile: tile)
        }
    }

    func startBattle(with card: Card) {
        defenderHasFirstStrike = false      // ★ 先制フラグをリセット

        guard let t = landedOnOpponentTileIndex,
              let defOwner = owner[t], defOwner != turn,
              card.kind == .creature
        else { return }
        
        willPoisonDefender = false
        
        let pid = turn
        guard paySummonCostIfNeeded(for: card, by: pid) else {
            return
        }

        // 戦闘中は End を押せない
        canEndTurn = false
        // 戦闘の対象タイルと攻撃カードを保持（Overlay 終了後に使う）
        currentBattleTile = t
        currentAttackingCard = card
        pendingBattleAttacker = turn
        isAwaitingBattleResult = true

        let atkStats = card.stats ?? CreatureStats.defaultLizard
        let attr = attributeAt(tile: t)

        // 左=攻撃者（あなた or CPU）、右=防御者（盤面クリーチャー）
        let attacker = BattleCombatant(
            name: (turn == 0 ? "あなた" : "CPU"),
            imageName: card.symbol,
            hp: atkStats.hpMax, hpMax: atkStats.hpMax,
            power: atkStats.power, durability: atkStats.durability,
            itemPower: 0, itemDurability: 0,
            resist: resistValue(of: atkStats, for: attr)
        )

        let defender = BattleCombatant(
            name: (defOwner == 0 ? "あなた" : "相手"),
            imageName: creatureOnTile[t]?.imageName ?? "enemyCreature",
            hp: hp.indices.contains(t) ? hp[t] : 0,
            hpMax: hpMax.indices.contains(t) ? hpMax[t] : 0,
            power: pow.indices.contains(t) ? pow[t] : 0,
            durability: dur.indices.contains(t) ? dur[t] : 0,
            itemPower: 0, itemDurability: 0,
            resist: defenderResistAt(tile: t, for: attr)
        )

        battleLeft = attacker
        battleRight = defender
        battleAttr = BattleAttribute(rawValue: attr.rawValue) ?? .normal
        if turn == 1 {
            cpuUseEquipSkillIfAvailable()
        }
        isBattleItemSelectionPhase = true
        showBattleOverlay = true
        landedOnOpponentTileIndex = t
    }
    
    func finishBattle(finalL: BattleCombatant, finalR: BattleCombatant) {
        guard isAwaitingBattleResult,
              let t = currentBattleTile,
              let usedCard = currentAttackingCard,
              let defOwner = owner.indices.contains(t) ? owner[t] : nil,
              let attackerId = pendingBattleAttacker
        else { return }

        showBattleOverlay = false
        isAwaitingBattleResult = false

        let attackerIsCPU = (attackerId == 1)
        let defenderId = defOwner

        if finalR.hp <= 0 {
            placeCreature(from: usedCard, at: t, by: attackerId)
            consumeFromHand(usedCard, for: attackerId)
            battleResult = attackerIsCPU ? "土地を奪われた" : "土地を奪い取った"
        } else if finalL.hp <= 0 {
            if hp.indices.contains(t) { hp[t] = finalR.hp; hp = hp }
            if var c = creatureOnTile[t] {
                c.hp = finalR.hp
                creatureOnTile[t] = c
            }
            transferToll(from: attackerId, to: defenderId, tile: t)
            consumeFromHand(usedCard, for: attackerId)
            battleResult = attackerIsCPU ? "通行料を奪った" : "通行料を奪われた"
        } else {
            if hp.indices.contains(t) { hp[t] = finalR.hp; hp = hp }
            if var c = creatureOnTile[t] { c.hp = finalR.hp; creatureOnTile[t] = c }
            transferToll(from: attackerId, to: defenderId, tile: t)
            battleResult = attackerIsCPU ? "通行料を奪った" : "通行料を奪われた"
        }
        if willPoisonDefender {
            // 防御側がまだ生きている場合だけ毒を付与
            if hp.indices.contains(t), hp[t] > 0 {
                poisonedTiles[t] = true

                // ★ バトル終了直後に毒エフェクトを1回再生
                let tileForPoison = t
                Task { @MainActor in
                    self.spellEffectTile = tileForPoison
                    self.spellEffectKind = .poison
                    // エフェクトの長さに合わせて 1 秒ほど表示
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if self.spellEffectTile == tileForPoison &&
                        self.spellEffectKind == .poison {
                        self.spellEffectTile = nil
                    }
                }
            }
            // 一度使ったらフラグをリセット
            willPoisonDefender = false
        }

        landedOnOpponentTileIndex = nil
        currentBattleTile = nil
        currentAttackingCard = nil
        pendingBattleAttacker = nil

        if attackerIsCPU {
            // ★ NPC が攻撃側だった場合：
            //   戦闘終了と同時にターン終了まで進める
            endTurn()
        } else {
            // プレイヤーが攻撃側のときは今まで通り
            canEndTurn = true
        }
    }
    
    private func transferToll(from payer: Int, to ownerPid: Int, tile: Int) {
        let fee = toll(at: tile)
        payToll(payer: payer, to: ownerPid, amount: fee)
    }
    
    // 所持金の増減は必ずここを通す
    func addGold(_ amount: Int, to player: Int) {
        guard players.indices.contains(player) else { return }
        let before = players[player].gold
        players[player].gold += amount
        logs.append("GOLD[\(player)] \(before) -> \(players[player].gold) (\(amount >= 0 ? "+" : "")\(amount))")
        if players[player].gold < 0 {
            startForcedSaleIfNeeded(for: player)
        }
    }
    
    // マイナスなら売却フロー開始（Youは手動、CPUは自動）
    func startForcedSaleIfNeeded(for player: Int) {
        guard players.indices.contains(player) else { return }
        let deficit = -players[player].gold
        guard deficit > 0 else { return }

        if player == 0 {
            // プレイヤー手動
            isForcedSaleMode = true
            debtAmount = deficit
        } else {
            // CPU 自動（最小合計で赤字解消）
            autoLiquidateCPU(target: deficit)
        }
    }

    // ▼ プレイヤー売却フロー：自軍タイルをタップ → 確認ポップ
    func requestSell(tile idx: Int) {
        guard isForcedSaleMode,
              owner.indices.contains(idx),
              owner[idx] == 0 else { return }
        let v = saleValue(for: idx)
        sellPreviewAfterGold = players[0].gold + v
        sellConfirmTile = idx
    }
    
    // ▼ 通行料支払いの共通口（最後にこれを呼ぶよう統一）
    func payToll(payer: Int, to ownerPlayer: Int, amount: Int) {
        addGold(-amount, to: payer)
        addGold(+amount, to: ownerPlayer)
        // addGold 内で必要なら強制売却フローが自動起動
    }
    
    // タイル index → TileAttribute を返すヘルパー
    private func tileAttribute(of tile: Int) -> TileAttribute {
        // tile は 0始まり（0..tileCount-1）
        guard terrain.indices.contains(tile) else { return .normal }
        return terrain[tile].attribute
    }

    // MARK: -----------------------------------------------------------------------------
    // MARK: - スペル管理
    // MARK: -----------------------------------------------------------------------------
    
    // MARK: - sp-elixir（任意マス全回復）用ヘルパー
    func cancelFullHealSelection() {
        restorePendingSpellUsage()
        // sp-elixir 用
        isSelectingFullHealTarget = false
        pendingFullHealTile = nil
        fullHealCandidateTiles = []
        battleResult = nil
        // sp-decay 用もまとめてリセットしておく
        isSelectingLandLevelChangeTarget = false
        pendingLandLevelChangeTile = nil
        landLevelChangeCandidateTiles = []
        // ★ sp-devastation 用
        isSelectingLandTollZeroTarget = false
        pendingLandTollZeroTile = nil
        landTollZeroCandidateTiles = []
        cancelDamageSelection()
        cancelPoisonSelection()
        cancelCleanseSelection()
        // ボードのハイライトも解除
        branchLandingTargets = []
    }

    func cancelFullHealConfirm() {
        // 「閉じる」で確認ウィンドウだけ閉じて、選択モードには戻る
        pendingFullHealTile = nil
    }

    func confirmFullHeal() {
        guard let tile = pendingFullHealTile else {
            cancelFullHealSelection()
            return
        }

        // 対象の妥当性チェック
        guard fullHealCandidateTiles.contains(tile),
              owner.indices.contains(tile),
              owner[tile] == 0,
              hp.indices.contains(tile),
              hpMax.indices.contains(tile)
        else {
            cancelFullHealSelection()
            return
        }

        let beforeHP = hp[tile]
        let maxHP = hpMax[tile]
        let heal = maxHP - beforeHP
        guard heal > 0 else {
            cancelFullHealSelection()
            return
        }

        guard finalizePendingSpellUsage() else {
            cancelFullHealSelection()
            return
        }

        // アニメーション付きで全回復
        Task { @MainActor in
            await self.applyFullHealAnimation(at: tile, heal: heal)
        }

        // 選択モード終了
        isSelectingFullHealTarget = false
        fullHealCandidateTiles = []
        branchLandingTargets = []
        pendingFullHealTile = nil
        battleResult = nil
    }
    
    /// 選択モード全体を終了（ウインドウもハイライトもまとめて解除）
    func cancelLandLevelChangeSelection() {
        restorePendingSpellUsage()
        isSelectingLandLevelChangeTarget = false
        pendingLandLevelChangeTile = nil
        landLevelChangeCandidateTiles = []
        branchLandingTargets = []
    }

    /// 「閉じる」で確認ダイアログだけ閉じ、選択モードには戻る
    func cancelLandLevelChangeConfirm() {
        pendingLandLevelChangeTile = nil
    }

    /// OK ボタンでレベルを 1 下げる
    func confirmLandLevelChange() {
        guard let tile = pendingLandLevelChangeTile else {
            cancelLandLevelChangeSelection()
            return
        }

        // 対象がまだ候補に含まれている & レベル情報があるかチェック
        guard landLevelChangeCandidateTiles.contains(tile),
              level.indices.contains(tile)
        else {
            cancelLandLevelChangeSelection()
            return
        }

        let curLevel = level[tile]
        // レベル2以上のみ対象のはずだが、念のため
        guard curLevel >= 2 else {
            cancelLandLevelChangeSelection()
            return
        }

        guard finalizePendingSpellUsage() else {
            cancelLandLevelChangeSelection()
            return
        }

        let newLevel = curLevel - 1
        level[tile] = newLevel

        // レベルアップ時と同じロジックで通行料を更新
        if toll.indices.contains(tile) {
            toll[tile] = toll(at: tile)
        }

        pushCenterMessage("土地のレベルを1下げました（Lv\(curLevel) → Lv\(newLevel)）")
        
        Task { @MainActor in
            await self.applyDecayAnimation(at: tile)
        }

        // 選択モード終了
        isSelectingLandLevelChangeTarget = false
        landLevelChangeCandidateTiles = []
        pendingLandLevelChangeTile = nil
        branchLandingTargets = []
    }
    
    func cancelLandTollZeroSelection() {
        restorePendingSpellUsage()
        isSelectingLandTollZeroTarget = false
        landTollZeroCandidateTiles = []
        pendingLandTollZeroTile = nil
        branchLandingTargets = []
    }

    func cancelLandTollZeroConfirm() {
        // 「閉じる」で確認ダイアログだけ閉じて、選択モードには戻る
        pendingLandTollZeroTile = nil
    }

    func confirmLandTollZero() {
        guard let tile = pendingLandTollZeroTile else {
            cancelLandTollZeroSelection()
            return
        }
        
        devastatedTiles.insert(tile)
        harvestedTiles.remove(tile)

        // 候補内 & 通行量情報あり
        guard landTollZeroCandidateTiles.contains(tile),
              toll.indices.contains(tile)
        else {
            cancelLandTollZeroSelection()
            return
        }

        let before = toll[tile]
        guard before > 0 else {
            // すでに0なら何もしない
            cancelLandTollZeroSelection()
            return
        }

        guard finalizePendingSpellUsage() else {
            cancelLandTollZeroSelection()
            return
        }

        // 通行量を0にする
        toll[tile] = 0

        pushCenterMessage("土地の通行量を 0 にしました（\(before)G → 0G）")

        // エフェクト再生
        Task { @MainActor in
            await self.applyDevastationAnimation(at: tile)
        }

        // 選択モード終了
        isSelectingLandTollZeroTarget = false
        landTollZeroCandidateTiles = []
        pendingLandTollZeroTile = nil
        branchLandingTargets = []
    }
    
    func cancelLandTollDoubleSelection() {
        restorePendingSpellUsage()
        isSelectingLandTollDoubleTarget = false
        landTollDoubleCandidateTiles = []
        pendingLandTollDoubleTile = nil
        branchLandingTargets = []
    }

    func cancelLandTollDoubleConfirm() {
        // 「閉じる」で確認ダイアログだけ閉じて、選択モードには戻る
        pendingLandTollDoubleTile = nil
    }

    func confirmLandTollDouble() {
        guard let tile = pendingLandTollDoubleTile else {
            cancelLandTollDoubleSelection()
            return
        }

        // 候補内 & 通行量情報あり
        guard landTollDoubleCandidateTiles.contains(tile),
              toll.indices.contains(tile)
        else {
            cancelLandTollDoubleSelection()
            return
        }

        let before = toll[tile]
        guard before > 0 else {
            cancelLandTollDoubleSelection()
            return
        }

        guard finalizePendingSpellUsage() else {
            cancelLandTollDoubleSelection()
            return
        }

        // ★ 収穫フラグ ON
        harvestedTiles.insert(tile)

        // toll(at:) で devastation / harvest / セットボーナス込みで再計算
        let newValue = toll(at: tile)
        toll[tile] = newValue

        pushCenterMessage("土地の通行量を 2 倍にしました（\(before)G → \(newValue)G）")

        // エフェクト再生
        Task { @MainActor in
            await self.applyHarvestAnimation(at: tile)
        }

        // 選択モード終了
        isSelectingLandTollDoubleTarget = false
        landTollDoubleCandidateTiles = []
        pendingLandTollDoubleTile = nil
        branchLandingTargets = []
    }

    func cancelPoisonSelection() {
        restorePendingSpellUsage()
        clearPoisonSelectionState()
    }

    private func clearPoisonSelectionState() {
        isSelectingPoisonTarget = false
        poisonCandidateTiles = []
        pendingPoisonTile = nil
        pendingPoisonSpellName = nil
        branchLandingTargets = []
        battleResult = nil
    }

    func cancelPoisonConfirm() {
        pendingPoisonTile = nil
    }

    func confirmPoisonSpell() {
        guard isSelectingPoisonTarget,
              let tile = pendingPoisonTile,
              poisonCandidateTiles.contains(tile) else {
            cancelPoisonSelection()
            return
        }

        let spellName = pendingPoisonSpellName
        guard finalizePendingSpellUsage() else {
            cancelPoisonSelection()
            return
        }

        clearPoisonSelectionState()

        Task { @MainActor in
            await self.applyPoisonSpell(to: tile, spellName: spellName)
        }
    }

    func cancelCleanseSelection() {
        restorePendingSpellUsage()
        clearCleanseSelectionState()
    }

    private func clearCleanseSelectionState() {
        isSelectingCleanseTarget = false
        cleanseCandidateTiles = []
        pendingCleanseTile = nil
        pendingCleanseSpellName = nil
        branchLandingTargets = []
        battleResult = nil
    }

    func cancelCleanseConfirm() {
        pendingCleanseTile = nil
    }

    func confirmCleanseSpell() {
        guard isSelectingCleanseTarget,
              let tile = pendingCleanseTile,
              cleanseCandidateTiles.contains(tile) else {
            cancelCleanseSelection()
            return
        }

        let spellName = pendingCleanseSpellName
        guard finalizePendingSpellUsage() else {
            cancelCleanseSelection()
            return
        }

        clearCleanseSelectionState()

        Task { @MainActor in
            await self.applyCleanseSpell(to: tile, spellName: spellName)
        }
    }

    func cancelDamageSelection() {
        restorePendingSpellUsage()
        clearDamageSelectionState()
    }

    private func clearDamageSelectionState() {
        isSelectingDamageTarget = false
        damageCandidateTiles = []
        pendingDamageTile = nil
        pendingDamageAmount = 0
        pendingDamageEffect = nil
        pendingDamageSpellName = nil
        branchLandingTargets = []
        battleResult = nil
    }

    func cancelDamageConfirm() {
        pendingDamageTile = nil
    }

    func confirmDamageSpell() {
        guard isSelectingDamageTarget,
              let tile = pendingDamageTile,
              damageCandidateTiles.contains(tile),
              pendingDamageAmount > 0 else {
            cancelDamageSelection()
            return
        }

        let amount = pendingDamageAmount
        let effect = pendingDamageEffect
        let spellName = pendingDamageSpellName

        guard finalizePendingSpellUsage() else {
            cancelDamageSelection()
            return
        }

        clearDamageSelectionState()

        Task { @MainActor in
            await self.applyDamageSpell(amount: amount,
                                        to: tile,
                                        boardEffect: effect,
                                        spellName: spellName)
        }
    }

    @MainActor
    private func applyDamageSpell(amount: Int,
                                  to tile: Int,
                                  boardEffect: BoardWideSpellEffectKind?,
                                  spellName: String?) async {
        guard hp.indices.contains(tile),
              hp[tile] > 0 else {
            pushCenterMessage("対象のクリーチャーが存在しません")
            return
        }

        let before = hp[tile]
        let actualDamage = min(amount, before)
        guard actualDamage > 0 else {
            pushCenterMessage("ダメージを与えられませんでした")
            return
        }

        let newHP = max(0, before - actualDamage)
        hp[tile] = newHP
        if var creature = creatureOnTile[tile] {
            creature.hp = newHP
            creatureOnTile[tile] = creature
        }
        hp = hp

        focusTile = tile
        isHealingAnimating = true
        healingAmounts = [tile: -actualDamage]

        let usesTileEffect = (boardEffect == nil)
        if usesTileEffect {
            spellEffectTile = tile
            spellEffectKind = .damage
        } else if let effect = boardEffect {
            triggerBoardWideEffect(effect)
        }

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        healingAmounts.removeAll()

        if usesTileEffect {
            spellEffectTile = nil
        }

        var message = "\(spellName ?? "スペル") で \(actualDamage) ダメージ"

        if newHP <= 0 {
            clearCreatureInfo(at: tile,
                              clearOwnerAndLevel: true,
                              resetToll: true)
            message += "（撃破）"
        }

        pushCenterMessage(message)

        try? await Task.sleep(nanoseconds: 200_000_000)
        isHealingAnimating = false
    }

    @MainActor
    private func applyPoisonSpell(to tile: Int, spellName: String?) async {
        guard creatureSymbol.indices.contains(tile),
              creatureSymbol[tile] != nil,
              hp.indices.contains(tile),
              hp[tile] > 0,
              poisonedTiles.indices.contains(tile) else {
            pushCenterMessage("対象のクリーチャーが存在しません")
            return
        }

        if poisonedTiles[tile] {
            pushCenterMessage("すでに毒状態です")
            return
        }

        poisonedTiles[tile] = true
        pushCenterMessage("\(spellName ?? "スペル") で毒状態にしました")

        let target = tile
        focusTile = target
        spellEffectTile = target
        spellEffectKind = .poison
        isHealingAnimating = true

        try? await Task.sleep(nanoseconds: 1_000_000_000)

        if spellEffectTile == target && spellEffectKind == .poison {
            spellEffectTile = nil
        }

        isHealingAnimating = false
    }

    @MainActor
    private func applyCleanseSpell(to tile: Int, spellName: String?) async {
        guard (0..<tileCount).contains(tile) else {
            pushCenterMessage("対象のマスが存在しません")
            return
        }

        var removed: [String] = []
        if poisonedTiles.indices.contains(tile), poisonedTiles[tile] {
            poisonedTiles[tile] = false
            removed.append("毒")
        }
        if devastatedTiles.contains(tile) {
            devastatedTiles.remove(tile)
            removed.append("荒廃")
        }
        if harvestedTiles.contains(tile) {
            harvestedTiles.remove(tile)
            removed.append("豊作")
        }

        if removed.isEmpty {
            pushCenterMessage("解除できる効果がありません")
            return
        }

        focusTile = tile
        triggerBoardWideEffect(.cure)

        if removed.contains(where: { $0 == "荒廃" || $0 == "豊作" }) {
            if toll.indices.contains(tile) {
                toll[tile] = toll(at: tile)
            }
        }

        let detail = removed.joined(separator: " / ")
        pushCenterMessage("\(spellName ?? "スペル") で \(detail) を解除")

        try? await Task.sleep(nanoseconds: 300_000_000)
    }

    @MainActor
    private func triggerBoardWideEffect(_ effect: BoardWideSpellEffectKind) {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeBoardWideEffect = effect
        }
        SoundManager.shared.playBoardWideEffectSound(effect)

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self else { return }
            if self.activeBoardWideEffect == effect {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.activeBoardWideEffect = nil
                }
            }
        }
    }

    @MainActor
    private func applyFullHealAnimation(at tile: Int, heal: Int) async {
        // --- まず HP を更新 ---
        let oldHp = hp[tile]
        let maxHp = hpMax[tile]
        let newHp = min(maxHp, oldHp + heal)
        hp[tile] = newHp

        let actualHeal = newHp - oldHp

        // --- SpellEffectScene 用：このマスにエフェクトを出す（回復） ---
        spellEffectTile = tile
        spellEffectKind = .heal

        // --- 既存の「数字が浮く」回復アニメ ---
        isHealingAnimating = true
        focusTile = tile
        healingAmounts = [tile: actualHeal]

        // 数字を少し表示
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        healingAmounts.removeAll()

        // ちょっと余韻
        try? await Task.sleep(nanoseconds: 300_000_000)   // 0.3秒

        isHealingAnimating = false

        // SpellEffectScene の SpriteView を消す
        spellEffectTile = nil
    }
    
    @MainActor
    private func applyDecayAnimation(at tile: Int) async {
        // SpellEffectScene 用：このマスに decay エフェクトを出す
        spellEffectTile = tile
        spellEffectKind = .decay
        focusTile = tile

        // 他の操作を一時的に止めたければ true にしておく（名前は流用）
        isHealingAnimating = true

        // おおよそ他のエフェクトと合わせて1秒程度表示
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isHealingAnimating = false
        spellEffectTile = nil
    }
    
    @MainActor
    private func applyDevastationAnimation(at tile: Int) async {
        // SpellEffectScene 用：このマスに devastation エフェクトを出す
        spellEffectTile = tile
        spellEffectKind = .devastation
        focusTile = tile

        // 他の操作を一時的に止めたければ true にしておく（名前は流用）
        isHealingAnimating = true

        // 他のエフェクトと同じく 1 秒程度表示
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isHealingAnimating = false
        spellEffectTile = nil
    }
    
    @MainActor
    private func applyHarvestAnimation(at tile: Int) async {
        // SpellEffectScene 用：このマスに harvest エフェクトを出す
        spellEffectTile = tile
        spellEffectKind = .harvest
        focusTile = tile

        // 他の操作を一時的に止めたければ true にしておく（名前は流用）
        isHealingAnimating = true

        // 他のエフェクトと同じくらい 1 秒程度表示
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        isHealingAnimating = false
        spellEffectTile = nil
    }

}

enum SpecialNodeKind { case castle, tower }

private let SPECIAL_NODES: [Int: SpecialNodeKind] = [
    0: .castle,  // マス1
    4: .tower,   // マス5
    20: .tower   // マス21
]

func specialNodeKind(for index: Int) -> SpecialNodeKind? {
    SPECIAL_NODES[index]
}

func isSpecialNode(_ index: Int) -> Bool {
    SPECIAL_NODES[index] != nil
}

enum SpecialActionSheet: Equatable {
    case levelUp(tile: Int)
    case moveFrom(tile: Int)
    case buySpell
}

struct ShopSpell: Identifiable, Equatable {
    let id: String
    let name: String
    let price: Int
    // 必要なら効果情報などをあとで拡張
}

extension ShopSpell {
    static let catalog: [ShopSpell] = [
        .init(id: "sp-dice1",  name: "ダイス1",   price: 10),
        .init(id: "sp-dice2",    name: "ダイス2",   price: 10),
        .init(id: "sp-dice3",      name: "ダイス3", price: 10),
        .init(id: "sp-dice4",      name: "ダイス4", price: 20),
        .init(id: "sp-dice5",      name: "ダイス5", price: 20),
        .init(id: "sp-dice6",      name: "ダイス6", price: 20),
        .init(id: "sp-hardFang",      name: "硬牙", price: 20),
        .init(id: "sp-bigScale",      name: "大鱗", price: 20),
        .init(id: "sp-draw2",      name: "ドロー2", price: 40)
    ]
}

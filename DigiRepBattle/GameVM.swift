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
    @Published var passedCP1: [Bool] = [false, false]
    @Published var passedCP2: [Bool] = [false, false]
    @Published var showCreatureMenu: Bool = false
    @Published var creatureMenuTile: Int? = nil
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
    
    private var cpuDidBattleThisTurn: Bool = false
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
    
    init() {
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
        
        //プレイヤーデッキ
        cardStates[0].collection.add("cre-defaultLizard", count: 30)
        cardStates[0].collection.add("sp-fireball",       count: 20)
        cardStates[0].deckList.creatureSlots = [
            "cre-defaultLizard": 30
        ]
        cardStates[0].deckList.spellSlots = [
            "sp-dice1": 20
        ]
        
        //NPCデッキ
        cardStates[1].collection.add("cre-defaultGecko", count: 30)
        cardStates[1].collection.add("sp-heal",          count: 20)
        cardStates[1].deckList.creatureSlots = [
            "cre-defaultGecko": 30
        ]
        cardStates[1].deckList.spellSlots = [
            "sp-dice1": 20
        ]
        
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
// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　ターン管理
// MARK: ---------------------------------------------------------------------------
    func endTurn() {
        showSpecialMenu = false
        beginTurnTransition()
    }
    
    func beginTurnTransition() {
        guard !isTurnTransition else { return }
        isTurnTransition = true

        // 3秒後にターン交代して演出終了
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            finishTurnTransition()
        }
    }

    func finishTurnTransition() {
        guard phase == .moved else { return }
        turn = 1 - turn
        phase = .ready
        lastRoll = 0
        startTurnIfNeeded()
        healOnBoard()
        focusTile = players[turn].pos
        if turn == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task { await self.runCpuAuto() }
            }
        }
        isTurnTransition = false
    }
    
    // 毎ターンなつき度分回復
    private func healOnBoard() {
        var touched = false
        for i in 0..<tileCount {
            guard owner[i] != nil, hpMax[i] > 0, hp[i] < hpMax[i] else { continue }
            let heal = max(0, aff[i] / 2)
            let newHP = min(hpMax[i], hp[i] + heal)
            if newHP != hp[i] {
                hp[i] = newHP
                touched = true
            }
            if var c = creatureOnTile[i] {
                c.hp = newHP
                creatureOnTile[i] = c
            }
        }
        if touched { hp = hp } // ← 再描画トリガ
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
    func startTurnIfNeeded() {
        guard phase == .ready else { return }
        // 手番のドロー
        drawOne(for: turn)
        // 6枚超過なら捨てフェーズ
        if hands[turn].count > 5 { mustDiscardFor = turn }
    }
    
    func confirmPlaceCreatureFromHand(_ card: Card, at tile: Int, by pid: Int) {
        guard canPlaceCreature(at: tile),
              owner.indices.contains(tile),
              owner[tile] == nil else {
            return
        }

        placeCreature(from: card, at: tile, by: pid)

        if let i = hands[pid].firstIndex(of: card) {
            hands[pid].remove(at: i)
        }

        canEndTurn = true
        showCreatureMenu = false
        creatureMenuTile = nil
    }
    
    private func drawOne(for pid: Int) {
        guard !decks[pid].isEmpty else { return }
        let idx = Int.random(in: 0..<decks[pid].count)
        let picked = decks[pid].remove(at: idx)   // ← ランダムで抜き取る
        hands[pid].append(picked)
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
    }

    func closeCardPopup() {
        presentingCard = nil
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
            return "敵クリーチャーに毒を付与する"
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
        pendingSwapHandIndex = nil
    }

// MARK: ---------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　サイコロ・移動
// MARK: ---------------------------------------------------------------------------
    func rollDice() {
        guard turn == 0, phase == .ready else { return }
        
        let r = nextForcedRoll[turn] ?? Int.random(in: 1...6)
        nextForcedRoll[turn] = nil
        forceRollToOneFor[turn] = false
        lastRoll = r
        stepsLeft = r
        // ★ ここがポイント：現在地がマス5で、これから動くなら、
        //   プレイヤーは先に分岐を選ばせ、CPUは即ランダム分岐してから移動開始
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

        let hasCreature = hands[turn].contains(where: { $0.kind == .creature })

        if !hasCreature {
            // ★ 強制通行料（プレイヤー/CPU共通）
            transferToll(from: turn, to: own, tile: t)
            battleResult = (turn == 1)
                ? "通行料を奪った"      // CPUが払ってあなたが受取
                : "通行料を奪われた"   // あなたが支払い
            landedOnOpponentTileIndex = nil
            expectBattleCardSelection = false
            canEndTurn = true
            return
        }

        if turn == 1 {
            // ★ CPUは自動で戦闘
            let attr = attributeAt(tile: t)
            if let creature = bestAttackerCard(in: hands[1], for: attr) {
                startBattle(with: creature)
                return
            }
        } else {
            // ★ プレイヤーは選択待ち（Endは有効のまま、"戦う"を押したら無効化）
            expectBattleCardSelection = false
            canEndTurn = true
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

        // マス5にいた状態から「選んだ先へ」即1歩進む（消費）
        players[turn].pos = chosenNext
        stepsLeft = max(0, stepsLeft - 1)
        focusTile = players[turn].pos
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
        let next = nextIndex(for: turn, from: cur)
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
        
        // 追加：自分のクリーチャーが置いてあるマスなら CreatureMenu を出す
        if isYou,
           owner.indices.contains(index),
           owner[index] == turn,
           level.indices.contains(index),
           level[index] >= 1,                          // 設置済み
           creatureSymbol.indices.contains(index),
           creatureSymbol[index] != nil {
            creatureMenuTile = index
            showCreatureMenu = true
        } else {
            creatureMenuTile = nil
            showCreatureMenu = false
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
    
    func useSpellPreRoll(_ card: Card, target: Int) {
        // 自分ターン・ロール前・スペルカードのみ
        guard turn == 0,
              phase == .ready,
              card.kind == .spell else { return }
        guard (0...1).contains(target) else { return }

        // ダイス固定スペルのみ対象
        guard case let .fixNextRoll(n)? = card.spell,
              (1...6).contains(n) else { return }

        // --- ① GOLDコスト支払い ---
        let cost = spellCost(of: card)
        if cost > 0 {
            guard tryPay(cost, by: 0) else {
                pushCenterMessage("GOLDが足りません（必要: \(cost)）")
                return
            }
        }

        // --- ② 効果適用 ---
        nextForcedRoll[target] = n

        // 手札から消費
        consumeFromHand(card, for: 0)

        if target == turn {
            // 自分に使ったときは即ロール
            pushCenterMessage("次のサイコロを \(n) に固定（コスト\(cost)）")
            rollDice()
        } else {
            // CPU に使ったときは次ターンの CPU ロールが固定される
            pushCenterMessage("CPUの次のサイコロを \(n) に固定（コスト\(cost)）")
            // phaseは .ready のまま。プレイヤーはこのままロール可能。
        }
    }

    func useSpellPreRoll(_ card: Card) {
        useSpellPreRoll(card, target: 0)
    }

    func useCardAfterMove(_ card: Card) {
        guard turn == 0, phase == .moved else { return }

        switch card.kind {
        case .spell:
            // マス移動後に使うスペルの入口
            useSpellAfterMove(card)

        case .creature:
            // 戦闘選択中なら「このカードで戦闘」
            if expectBattleCardSelection,
               landedOnOpponentTileIndex != nil {
                startBattle(with: card)
                return
            }

            let t = players[0].pos
            if owner[t] == nil, canPlaceCreature(at: t) {
                placeCreature(from: card, at: t, by: 0)
                consumeFromHand(card, for: 0)
            }
        }
    }
    
    func useSpellAfterMove(_ card: Card) {
        guard turn == 0,
              phase == .moved,
              card.kind == .spell else { return }

        guard let effect = card.spell else { return }

        let cost = spellCost(of: card)
        if cost > 0 {
            guard tryPay(cost, by: 0) else {
                pushCenterMessage("GOLDが足りません（必要: \(cost)）")
                return
            }
        }

        switch effect {

        case .fixNextRoll(let n) where (1...6).contains(n):
            nextForcedRoll[0] = n
            pushCenterMessage("次のサイコロを \(n) に固定（コスト\(cost)）")

        case .doubleDice:
            pushCenterMessage("スペル『\(card.name)』の効果（ダブルダイス）は未実装です")

        case .buffPower, .buffDefense, .teleport, .healHP,
             .firstStrike, .poison, .reflectSkill,
             .drawCards, .discardOpponentCards,
             .fullHealAnyCreature, .changeLandLevel,
             .setLandTollZero, .multiplyLandToll,
             .damageAnyCreature,
             .gainGold, .stealGold,
             .inspectCreature,
             .aoeDamageByResist,
             .changeTileAttribute,
             .purgeAllCreatures:
            pushCenterMessage("スペル『\(card.name)』の効果はまだ未実装です（コスト\(cost)だけ消費）")

        // ★ 追加：万一新しいケースが増えてもここで拾う
        default:
            pushCenterMessage("未対応のスペル効果です（コスト\(cost)だけ消費）")
        }

        // 手札から消費
        consumeFromHand(card, for: 0)
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

        // ③ GOLD奪取（とりあえずシンプルに実装）
        case let .stealGold(n):
            let other = 1 - pid
            guard players.indices.contains(other) else { return }
            let stolen = min(players[other].gold, n)
            addGold(-stolen, to: other)
            addGold(+stolen, to: pid)
            pushCenterMessage("\(stolen)GOLD を奪った")

        // それ以外はあとで個別実装
        default:
            pushCenterMessage("このスペル効果はまだ未実装です")
        }
    }


    private func consumeFromHand(_ card: Card, for pid: Int) {
        if let i = hands[pid].firstIndex(of: card) { hands[pid].remove(at: i) }
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

        // ロール確定
        lastRoll = nextForcedRoll[1] ?? Int.random(in: 1...6)
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

        // ここに来た時点で players[1].pos は“移動後”
        let t = players[1].pos

        if cpuDidBattleThisTurn {
            cpuDidBattleThisTurn = false
            endTurn()
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

        // 移動後：空き地なら設置
        if owner[t] == nil,
           canPlaceCreature(at: t),
           let creature = hands[1].first(where: { $0.kind == .creature }) {
            placeCreature(from: creature, at: t, by: 1)
            consumeFromHand(creature, for: 1)
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        endTurn()
    }
    
    private func cpuUseRandomDiceFixSpellIfAvailable() {
        if nextForcedRoll[1] != nil { return }
        // hands[1] から fixNextRoll(n) を集めてランダムに1枚使う
        let candidates: [(idx: Int, n: Int)] = hands[1].enumerated().compactMap { (i, c) in
            guard c.kind == .spell else { return nil }
            if case let .fixNextRoll(n)? = c.spell, (1...6).contains(n) {
                return (i, n)
            }
            return nil
        }

        guard let pick = candidates.randomElement() else { return }
        // 使ったカードを取り除き、次のサイコロ値を固定
        let (idx, n) = pick
        _ = hands[1].remove(at: idx)
        nextForcedRoll[1] = n
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

    // MARK: - マス管理
    
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

        // 四捨五入で整数化（必要に応じて切り捨てに変更可）
        return Int((Double(base) * mult).rounded())
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
    
    func placeCreature(from card: Card, at tile: Int, by pid: Int) {
        guard canPlaceCreature(at: tile) else { return }
        let s = card.stats ?? CreatureStats.defaultLizard
        let price = max(0, s.cost)
        
        guard tryPay(price, by: pid) else {
            if pid == 0 {
                battleResult = "GOLD不足（必要: \(price)）"
            }
            return
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
        hp = hp
        creatureOnTile[tile] = Creature(
            id: UUID().uuidString,
            owner: pid,
            imageName: card.symbol,  // 専用画像があればそちらに
            stats: s,
            hp: s.hpMax
        )
        toll[tile] = toll(at: tile)
    }
    
    /// マスの属性を返す
    private func attributeAt(tile: Int) -> TileAttribute {
        guard terrain.indices.contains(tile) else { return .normal }
        return terrain[tile].attribute
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
        // 自分の所有なら全表示。敵は基本HP以外非表示。
        return creature.owner == viewer
        // 例: 鑑定アイテム所持時は true を返す分岐を足せる
        // if revealAllForEnemy { return true }
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

        return CreatureInspectView(
            tileIndex: tile,
            mapImageName: mapImg,
            mapAttribute: mapAttrJP,
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
    
    // タイルタップ時ハンドラ（クリーチャーがいないタイルは無視）
    func tapTileForInspect(_ index: Int) {
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
        if owner.indices.contains(idx) { owner[idx] = nil }
        if level.indices.contains(idx) { level[idx] = 0 }
        if toll.indices.contains(idx)  { toll[idx]  = 0 }
        if creatureSymbol.indices.contains(idx) { creatureSymbol[idx] = nil }

        // TOTAL 表示がある場合はここで再計算を呼ぶ
        // recalcTotal(for: player)
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
            // 例）基礎100 × レベル
            toll[tile] = 100 * newLevel
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

        // 元をクリア
        owner[from] = nil
        level[from] = 0
        creatureSymbol[from] = nil
        hp[from] = 0
        hpMax[from] = 0
        toll[from] = 0

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
    
    // MARK: - 戦闘管理
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
        expectBattleCardSelection = true
        canEndTurn = false            // ← End無効化
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
            // ※手元のプロジェクトに合わせて適宜調整してください
            return highestResistAt(tile: tile)
        }
    }

    func startBattle(with card: Card) {
        guard let t = landedOnOpponentTileIndex,
              let defOwner = owner[t], defOwner != turn,
              card.kind == .creature
        else { return }

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
        
        showBattleOverlay = true
        expectBattleCardSelection = false
        landedOnOpponentTileIndex = t
    }
    
    func finishBattle(finalL: BattleCombatant, finalR: BattleCombatant) {
        guard isAwaitingBattleResult,
              let t = currentBattleTile,
              let usedCard = currentAttackingCard,
              let defOwner = owner.indices.contains(t) ? owner[t] : nil,
              let attackerId = pendingBattleAttacker
        else { return }

        // Overlay を閉じる
        showBattleOverlay = false
        isAwaitingBattleResult = false

        let attackerIsCPU = (attackerId == 1)
        let defenderId = defOwner

        if finalR.hp <= 0 {
            placeCreature(from: usedCard, at: t, by: attackerId)
            consumeFromHand(usedCard, for: attackerId)
            battleResult = attackerIsCPU ? "土地を奪われた" : "土地を奪い取った"
        } else {
            if hp.indices.contains(t) { hp[t] = finalR.hp; hp = hp }
            if var c = creatureOnTile[t] { c.hp = finalR.hp; creatureOnTile[t] = c }

            transferToll(from: attackerId, to: defenderId, tile: t)
            battleResult = attackerIsCPU ? "通行料を奪った" : "通行料を奪われた"
        }

        landedOnOpponentTileIndex = nil
        currentBattleTile = nil
        currentAttackingCard = nil
        pendingBattleAttacker = nil

        canEndTurn = true
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

}

// MARK: - Special Node Actions
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
        .init(id: "heal_small",  name: "薬小",   price: 30),
        .init(id: "heal_mid",    name: "薬大",   price: 60),
        .init(id: "atk_up",      name: "赤プロテイン小", price: 60),
        .init(id: "atk_up_big",      name: "赤プロテイン大", price: 200),
        .init(id: "def_up",      name: "青プロテイン小", price: 60),
        .init(id: "def_up_big",      name: "青プロテイン大", price: 200)
    ]
}

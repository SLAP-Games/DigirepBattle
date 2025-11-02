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
    // マップ
    let tileIndex: Int
    let mapImageName: String
    let mapAttribute: String  // 表示用（日本語化など）

    // クリーチャー
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
    // 分岐UI用（RingBoardViewへ渡す）
    @Published var branchSource: Int? = nil
    @Published var branchCandidates: [Int] = []
    @Published var focusTile: Int? = nil
    
    // 移動管理
    private var stepsLeft: Int = 0
    private let CROSS_NODE = 4
    private let CROSS_CHOICES = [3, 5, 27, 28]
    private let CHECKPOINTS: Set<Int> = [0, 4, 20]
    // 盤（角を重ねた二重スクエア＝31ノード）
    let sideCount: Int = 5
    let tileCount: Int

    // マス占領状態
    @Published var owner: [Int?]      // nil=未占領, 0=You, 1=CPU
    @Published var level: [Int]       // 0=未設置, 設置時は1
    @Published var creatureSymbol: [String?] // "lizard.fill" など
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
    private var spellPool: [Card] = []
    private var creaturePool: [Card] = []

    // プレイヤー
    @Published var players: [Player] = [
        Player(name: "You", pos: 0, gold: 300),
        Player(name: "CPU", pos: 0, gold: 300)
    ]
    @Published var turn: Int = 0                // 0=You, 1=CPU
    @Published var lastRoll: Int = 0
    @Published var phase: Phase = .ready        // .ready(前) → .rolled(後) → .moved(後処理)
    @Published var mustDiscardFor: Int? = nil   // 捨てる必要がある手番（0 or 1）: UI表示用
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
    
    private var moveDir: [Dir] = [.cw, .cw]
    private var branchCameFrom: Int? = nil
    var levelUpCost: [Int: Int] { [2: 100, 3: 250, 4: 500, 5: 900] }
    private var goldRef: WritableKeyPath<Player, Int> { \.gold }   // Player に gold がある想定
    
    private let nextCW: [Int] = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0,
        17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 4, 29, 30, 16
    ]
    
    private let nextCCW: [Int] = [
        15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        30, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 4, 28, 29
    ]

    // デッキ＆手札
    private var decks: [[Card]] = [[], []]
    @Published var hands: [[Card]] = [[], []]

    // スペル効果：次のロールを1に固定
    private var forceRollToOneFor: [Bool] = [false, false]
    
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
        
        self.spellPool = buildSpellPool()
        self.creaturePool = buildCreaturePool()
        let playerSpells = Array(spellPool.prefix(20))
        let playerCreatures = makePlayerFixedCreatureCards()
        decks[0] = (playerSpells + playerCreatures)
        // ※各ターンのドローは既にランダム抜き取り（drawOne）なので十分ランダム性あり

        // CPUのデッキ：今回はプレイヤーと同じにしておく（必要なら変えてOK）
        let cpuSpells = Array(spellPool.dropFirst(20).prefix(20))
        let cpuCreatures = makePlayerFixedCreatureCards()
        decks[1] = (cpuSpells + cpuCreatures)

        // 初期手札3枚
        for pid in 0...1 {
            for _ in 0..<3 { drawOne(for: pid) }
        }

        startTurnIfNeeded()
        self.focusTile = players[turn].pos
        self.terrain = buildFixedTerrain()
    }
    
    private func makePlayerFixedCreatureCards() -> [Card] {
        func reptile(_ name: String, _ stats: CreatureStats, _ n: Int) -> [Card] {
            (0..<n).map { _ in Card(kind: .creature, name: name, symbol: name, stats: stats) }
            // symbol に画像アセット名を入れる（＝手札＆設置の表示名）
        }

        return
            reptile("defaultLizard1",        .defaultLizard,        3) +
            reptile("defaultGecko1",         .defaultGecko,         3) +
            reptile("defaultCrocodile1",     .defaultCrocodile,     3) +
            reptile("defaultSnake1",         .defaultSnake,         3) +
            reptile("defaultIguana1",        .defaultIguana,        3) +
            reptile("defaultTurtle1",        .defaultTurtle,        3) +
            reptile("defaultFrog1",          .defaultFrog,          3) +
            reptile("defaultBeardedDragon1", .defaultBeardedDragon, 2) +
            reptile("defaultLeopardGecko1",  .defaultLeopardGecko,  2) +
            reptile("defaultNileCrocodile1", .defaultNileCrocodile, 1) +
            reptile("defaultBallPython1",    .defaultBallPython,    1) +
            reptile("defaultGreenIguana1",   .defaultGreenIguana,   1) +
            reptile("defaultaStarTurtle1",   .defaultaStarTurtle,   1) +
            reptile("defaultHornedFrog1",    .defaultHornedFrog,    1)
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

        // ご指定の固定割り当て（タイル番号は 1..31）
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
    
    private func nextIndex(for pid: Int, from cur: Int) -> Int {
        switch moveDir[pid] {
        case .cw:  return nextCW[cur]
        case .ccw: return nextCCW[cur]
        }
    }
    
    private func buildSpellPool() -> [Card] {
        (1...30).map { i in
            let name = String(format: "スペル（S%02d）", i)
            return Card(kind: .spell, name: name, symbol: "sun.max.fill")
        }
    }

    private func buildCreaturePool() -> [Card] {
        (1...60).map { i in
            let name = String(format: "クリーチャー（C%02d）", i)
            var c = Card(kind: .creature, name: name, symbol: "lizard.fill")
            c.stats = .defaultLizard
            return c
        }
    }

    /// 固定50枚（順序固定）。※シャッフルしない
    private func makeFixedDeck() -> [Card] {
        let spells = Array(spellPool.prefix(20))       // S01..S20
        let creatures = Array(creaturePool.prefix(30)) // C01..C30
        // 既存が popLast() なら、末尾が「山札の上」だが、
        // 今回はドロー時にランダム化するのでそのままでOK
        return spells + creatures
    }

    // MARK: - ターン管理
    func startTurnIfNeeded() {
        guard phase == .ready else { return }
        // 手番のドロー
        drawOne(for: turn)
        // 5枚超過なら捨てフェーズ
        if hands[turn].count > 4 { mustDiscardFor = turn }
    }

    func endTurn() {
        guard phase == .moved else { return }
        turn = 1 - turn
        phase = .ready
        lastRoll = 0
        startTurnIfNeeded()
        
        healOnBoard()
        
        focusTile = players[turn].pos
        if turn == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.runCpuAuto()
            }
        }
    }
    
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

    // MARK: - 山札・手札
    private func drawOne(for pid: Int) {
        guard !decks[pid].isEmpty else { return }
        let idx = Int.random(in: 0..<decks[pid].count)
        let picked = decks[pid].remove(at: idx)   // ← ランダムで抜き取る
        hands[pid].append(picked)
    }

    func discard(_ card: Card, for pid: Int) {
        if let idx = hands[pid].firstIndex(of: card) {
            hands[pid].remove(at: idx)
        }
        mustDiscardFor = nil
    }

    // MARK: - サイコロ
    func rollDice() {
        guard turn == 0, phase == .ready else { return }
        let r = forceRollToOneFor[turn] ? 4 : Int.random(in: 1...6)
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
            return
        }
        phase = .moving
        continueMove()
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
                ? "通行料を奪った（マス\(t+1)）"      // CPUが払ってあなたが受取
                : "通行料を奪われた（マス\(t+1)）"   // あなたが支払い
            landedOnOpponentTileIndex = nil
            expectBattleCardSelection = false
            canEndTurn = true
            return
        }

        if turn == 1 {
            // ★ CPUは自動で戦闘
            if let creature = hands[1].first(where: { $0.kind == .creature }) {
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
    }

    // MARK: - カード使用（プレイヤー）
    func useSpellPreRoll(_ card: Card) {
        // 前ロール専用：スペルのみ
        guard turn == 0, phase == .ready, card.kind == .spell else { return }
        consumeFromHand(card, for: 0)
        forceRollToOneFor[0] = true
        // スペル後は自動でロール→移動
        rollDice()
    }

    func useCardAfterMove(_ card: Card) {
        guard turn == 0, phase == .moved else { return }
        switch card.kind {
        case .spell:
            // 次回ロール固定
            consumeFromHand(card, for: 0)
            forceRollToOneFor[0] = true
        case .creature:
            // 戦闘選択中なら「このカードで戦闘」
            if expectBattleCardSelection, landedOnOpponentTileIndex != nil {
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

    private func consumeFromHand(_ card: Card, for pid: Int) {
        if let i = hands[pid].firstIndex(of: card) { hands[pid].remove(at: i) }
    }

    // MARK: - CPU 自動
    private func runCpuAuto() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            // 捨て必要ならランダム捨て
            if self.hands[1].count > 4 {
                if let c = self.hands[1].randomElement() { self.discard(c, for: 1) }
            }
            // 前ロール：スペルがあれば1枚使う
            if let spell = self.hands[1].first(where: { $0.kind == .spell }) {
                self.consumeFromHand(spell, for: 1)
                self.forceRollToOneFor[1] = true
            }
            
            // ロール→自動移動
            self.lastRoll = self.forceRollToOneFor[1] ? 1 : Int.random(in: 1...6)
            self.forceRollToOneFor[1] = false
            self.stepsLeft = self.lastRoll
            // ★ CPUがマス5開始＆動くなら、先にランダム分岐を適用
            if self.players[1].pos == self.CROSS_NODE, self.stepsLeft > 0 {
                if let choice = self.CROSS_CHOICES.randomElement() {
                    self.applyBranchChoice(choice)
                }
            }
            self.phase = .moving
            self.continueMove()

            // 移動後：空き地ならクリーチャーを1枚置く
            let t = self.players[1].pos
            if self.owner[t] == nil,
               self.canPlaceCreature(at: t),
               let creature = self.hands[1].first(where: { $0.kind == .creature }) {
                self.placeCreature(from: creature, at: t, by: 1)  // ← これに変更
                self.consumeFromHand(creature, for: 1)
            }

            // ターン終了
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.endTurn() // プレイヤーへ戻る（startTurnIfNeeded が実行される）
            }
        }
    }

    // 料金計算（Lv1=30）
    func toll(at tile: Int) -> Int {
        let lv = level[tile]
        if lv == 1 {
            return lv <= 0 ? 0 : (30 * 1)
        } else if lv == 2 {
            return lv <= 0 ? 0 : (30 * 2)
        } else if lv == 3 {
            return lv <= 0 ? 0 : (30 * 4)
        } else if lv == 4 {
            return lv <= 0 ? 0 : (30 * 8)
        } else if lv == 5 {
            return lv <= 0 ? 0 : (30 * 16)
        } else {
            return lv <= 0 ? 0 : (30 * (16 + lv))
        }
    }
    
    func placeCreature(from card: Card, at tile: Int, by pid: Int) {
        guard canPlaceCreature(at: tile) else { return }
        let s = card.stats ?? CreatureStats.defaultLizard
        let price = max(0, s.cost)
        
        guard tryPay(price, by: pid) else {
            if pid == 0 {
                // プレイヤーにはメッセージ（CPUは不要なら表示しない）
                battleResult = "GOLD不足で設置できません（必要: \(price)）"
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
            ? "通行料を奪った（マス\(t+1)）"      // CPUが支払ってあなたが受け取り
            : "通行料を奪われた（マス\(t+1)）"   // あなたが支払い
        landedOnOpponentTileIndex = nil
        expectBattleCardSelection = false
        canEndTurn = true
    }
    
    private func highestResistAt(tile: Int) -> Int {
        max(rDry[tile], rWat[tile], rHot[tile], rCold[tile])
    }
    
    func showSingleLog(_ message: String) {
        logs = [message]          // ← 配列を丸ごと置き換え（過去分を消す）
        showLogOverlay = true
    }
    

    func startBattle(with card: Card) {
        guard let t = landedOnOpponentTileIndex,
              let defOwner = owner[t],
              defOwner != turn,
              card.kind == .creature
        else { return }

        // 先手：攻撃側→守備側
        let attackerIsCPU = (turn == 1)
        let atkStats = card.stats ?? CreatureStats.defaultLizard
        let defHighest = highestResistAt(tile: t)
        
        let atk1 = (atkStats.power + atkStats.highestResist) * 2
        let def1 = dur[t] + atkStats.highestResist
        let dmg1 = max(0, atk1 - def1)
        hp[t] = max(0, hp[t] - dmg1)
        hp = hp
        if var c = creatureOnTile[t] {
            c.hp = hp[t]
            creatureOnTile[t] = c
        }

        if hp[t] <= 0 {
            // 撃破 → 奪取
            placeCreature(from: card, at: t, by: turn)
            consumeFromHand(card, for: turn)
            battleResult = attackerIsCPU
                ? "土地を奪われた（マス\(t+1)）"
                : "土地を奪い取った（マス\(t+1)）"
            canEndTurn = true
            landedOnOpponentTileIndex = nil
            expectBattleCardSelection = false
            return
        }

        // 反撃：守備側→攻撃側
        let atk2 = (pow[t] + defHighest) * 2
        let def2 = atkStats.durability + defHighest
        let dmg2 = max(0, atk2 - def2)

        var atkHP = atkStats.hpMax
        atkHP = max(0, atkHP - dmg2)

        if atkHP <= 0 {
            // 攻撃側が倒れ → 通行料
            consumeFromHand(card, for: turn)
            transferToll(from: turn, to: defOwner, tile: t)
            let before = players[turn].gold
            let fee = toll(at: t)
            players[turn].gold = max(0, before - fee)
            battleResult = attackerIsCPU
                ? "通行料を奪った"
                : "通行料を奪われた\n\(before)→\(players[turn].gold)"
            canEndTurn = true
        } else {
            transferToll(from: turn, to: defOwner, tile: t)
            let before = players[turn].gold
            let fee = toll(at: t)
            players[turn].gold = max(0, before - fee)
            battleResult = attackerIsCPU
                ? "通行料を奪った"
                : "通行料を奪われた\n\(before)→\(players[turn].gold)"
            canEndTurn = true
        }

        landedOnOpponentTileIndex = nil
        expectBattleCardSelection = false
    }
    
    private func transferToll(from payer: Int, to ownerPid: Int, tile: Int) {
        let fee = toll(at: tile)
        let before = players[payer].gold
        players[payer].gold = max(0, before - fee)
        players[ownerPid].gold += fee
    }
    
    func clearBattleResult() {
        battleResult = nil
    }
    
    // 1歩ずつ前進し、交差点(マス5)に入ったら分岐UIを出して一時停止
    private func continueMove() {
        while stepsLeft > 0 {
            advanceOneStep()
            // 分岐停止中ならループ中断（ユーザー選択を待つ）
            if branchSource != nil { return }
        }
        phase = .moved
        // ここで landedOnOpponentTileIndex など既存処理を続ける
        didStop(at: players[turn].pos, isYou: turn == 0)
        handleAfterMove()
        focusTile = players[turn].pos
        
    }
    
    // 既存の「次のマス」算出を利用して1歩進める
    private func advanceOneStep() {
        // まず通常の1歩前進
        let cur = players[turn].pos
        let next = nextIndex(for: turn, from: cur)
        players[turn].pos = next
        stepsLeft -= 1
        awardCheckpointIfNeeded(entering: next, pid: turn)
        
        if next == CROSS_NODE, stepsLeft > 0 {
            // 分岐候補（来た方向は禁止）
            let cameFrom = cur
            let filtered = CROSS_CHOICES.filter { $0 != cameFrom }

            if turn == 0 {
                // プレイヤー: UI表示して停止
                branchCameFrom = cameFrom
                branchSource = CROSS_NODE
                branchCandidates = filtered
                phase = .branchSelecting
                return
            } else {
                // CPU: その場でランダム選択→即適用（1歩消費して選択先へ）
                if let choice = filtered.randomElement() {
                    applyBranchChoice(choice)
                }
                // CPUは止めずに続行（stepsLeftが0または分岐で0ならループで止まる）
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

        // 残りがあれば移動継続、なければ後処理へ
        if stepsLeft > 0 {
            phase = .moving
            continueMove()
        } else {
            phase = .moved
            handleAfterMove()
        }
    }
    
    // === 追加: 設置可否チェック ===
    func canPlaceCreature(at index: Int) -> Bool {
        return !isSpecialNode(index)
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
        pushCenterMessage("レベルUPする自分のマスをタップしてください")
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
        pushCenterMessage("クリーチャーを移動する元のマスをタップしてください")
    }

    /// スペル購入シートを表示
    func actionPurchaseSkillOnSpecialNode() {
        activeSpecialSheet = .buySpell
    }

    func actionEndTurnFromSpecialNode() {
        // TODO: ターン終了の処理
        showSpecialMenu = false
        currentSpecialKind = nil
        endTurn()
        // ここで既存のターン終了ハンドラを呼ぶ等
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
    // GameVM
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
        CHECKPOINTS.contains(index)
    }
    
    private func ownedTileCount(of pid: Int) -> Int {
        owner.reduce(0) { $0 + (($1 == pid) ? 1 : 0) }
    }

    // 300 + (自分の設置マス数 × 30)
    private func checkpointReward(for pid: Int) -> Int {
        300 + ownedTileCount(of: pid) * 30
    }

    // タイルに「入った」タイミングで呼ぶ
    private func awardCheckpointIfNeeded(entering index: Int, pid: Int) {
        guard isCheckpoint(index) else { return }
        let gain = checkpointReward(for: pid)
        players[pid].gold += gain
        if pid == 0 {
            lastCheckpointGain = gain
            checkpointMessage = "チェックポイント通過　\(gain) GOLD獲得！"
            showCheckpointOverlay = true
        }
    }

    // ポップアップを閉じる
    func closeCheckpointOverlay() {
        showCheckpointOverlay = false
        checkpointMessage = nil
    }

    // MARK: 実行（シートから確定時に呼ぶ）

    /// レベルアップ確定
    func confirmLevelUp(tile: Int, to newLevel: Int) {
        guard owner.indices.contains(tile), owner[tile] == turn else { return }
        guard level.indices.contains(tile) else { return }
        let cur = level[tile]
        guard newLevel >= 2, newLevel <= 5, newLevel > cur else { return }
        guard let cost = levelUpCost[newLevel] else { return }

        if players[turn][keyPath: goldRef] < cost { return } // 足りない

        players[turn][keyPath: goldRef] -= cost
        level[tile] = newLevel

        // 通行料などをレベル依存で再計算したい場合
        if toll.indices.contains(tile) {
            // 例）基礎100 × レベル
            toll[tile] = 100 * newLevel
        }

        // ログやフローティングメッセージ
        pushCenterMessage("マス\(tile + 1) を Lv\(newLevel) に強化！ -\(cost)G")

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

        pushCenterMessage("マス\(from + 1)のクリーチャーを マス\(to + 1)へ移動")
        activeSpecialSheet = nil
        objectWillChange.send()
    }

    /// スペル購入確定
    func confirmPurchaseSpell(_ spell: ShopSpell) {
        guard players[turn][keyPath: goldRef] >= spell.price else { return }
        players[turn][keyPath: goldRef] -= spell.price

        // 手札に追加（あなたのカード実装に合わせてここだけ調整）
        addSpellCardToHand(spellID: spell.id, displayName: spell.name)

        pushCenterMessage("\(spell.name) を購入！ -\(spell.price)G")
        handleHandOverflowIfNeeded()  // 5枚超の処理があるなら実装済み関数を呼ぶ
        activeSpecialSheet = nil
        objectWillChange.send()
    }

    // MARK: - ユーティリティ（必要に応じて中身を既存実装に接続）

    /// 中央オーバーレイに短文を出す（既存の仕組みに繋いでください）
    private func pushCenterMessage(_ text: String) {
        battleResult = text
        logs.append(text)
    }

    /// 手札へスペルを追加（あなたの Card/Hand 実装に合わせて置き換え）
    private func addSpellCardToHand(spellID: String, displayName: String) {
        let card = Card(kind: .spell, name: displayName, symbol: "sun.max.fill")
        hands[turn].append(card)
    }

    /// 手札上限処理（>4 のとき捨てフェーズ等へ）
    private func handleHandOverflowIfNeeded() {
        if hands[turn].count > 4 {
            mustDiscardFor = turn
        }
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
        .init(id: "heal_small",  name: "ヒールS",   price: 80),
        .init(id: "heal_mid",    name: "ヒールM",   price: 150),
        .init(id: "atk_up",      name: "攻撃アップ", price: 120),
        .init(id: "def_up",      name: "防御アップ", price: 120),
        .init(id: "dash",        name: "ダッシュ",   price: 100)
    ]
}

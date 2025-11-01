//
//  GameVM.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI
import Foundation
import Combine

@MainActor
final class GameVM: ObservableObject {
    // 分岐UI用（RingBoardViewへ渡す）
    @Published var branchSource: Int? = nil
    @Published var branchCandidates: [Int] = []
    
    // 移動管理
    private var stepsLeft: Int = 0

    private let CROSS_NODE = 4
    private let CROSS_CHOICES = [3, 5, 27, 28]
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

    // プレイヤー
    @Published var players: [Player] = [
        Player(name: "You", pos: 0, gold: 500),
        Player(name: "CPU", pos: 0, gold: 500)
    ]
    @Published var turn: Int = 0                // 0=You, 1=CPU
    @Published var lastRoll: Int = 0
    @Published var phase: Phase = .ready        // .ready(前) → .rolled(後) → .moved(後処理)
    @Published var mustDiscardFor: Int? = nil   // 捨てる必要がある手番（0 or 1）: UI表示用
    @Published var showLogOverlay: Bool = false
    @Published var canEndTurn: Bool = true

    enum Phase { case ready, rolled, moving, branchSelecting, moved }
    enum Dir { case cw, ccw }
    private var moveDir: [Dir] = [.cw, .cw]
    private var branchCameFrom: Int? = nil
    
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
    // バトル用のUI状態
    @Published var landedOnOpponentTileIndex: Int? = nil
    @Published var expectBattleCardSelection: Bool = false
    @Published var logs: [String] = []
    @Published var battleResult: String? = nil
    
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

        // デッキ生成（30枚：spell×10, creature×20）＆シャッフル
        for pid in 0...1 {
            var deck: [Card] = []
            // スペル10枚（全部「次回サイコロ=1」）
            for i in 1...10 {
                deck.append(Card(kind: .spell,    name: "固定1（S\(i))", symbol: "sun.max.fill"))
            }
            // クリーチャー20枚
            for i in 1...20 {
                var c = Card(kind: .creature, name: "トカゲ（C\(i))", symbol: "lizard.fill")
                c.stats = CreatureStats.defaultLizard
                deck.append(c)
            }
            decks[pid] = deck.shuffled()

            // 初期手札3枚
            for _ in 0..<3 { drawOne(for: pid) }
        }
        startTurnIfNeeded()
    }
    
    private func nextIndex(for pid: Int, from cur: Int) -> Int {
        switch moveDir[pid] {
        case .cw:  return nextCW[cur]
        case .ccw: return nextCCW[cur]
        }
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

        if turn == 1 {
            // CPU自動行動
            runCpuAuto()
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
        }
        if touched { hp = hp } // ← 再描画トリガ
    }

    // MARK: - 山札・手札
    private func drawOne(for pid: Int) {
        guard let c = decks[pid].popLast() else { return }
        hands[pid].append(c)
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
        let r = forceRollToOneFor[turn] ? 1 : Int.random(in: 1...6)
        forceRollToOneFor[turn] = false
        lastRoll = r
        stepsLeft = r
        // ★ ここがポイント：現在地がマス5で、これから動くなら、
        //   プレイヤーは先に分岐を選ばせ、CPUは即ランダム分岐してから移動開始
        if players[turn].pos == CROSS_NODE, stepsLeft > 0 {
            // プレイヤー
            branchSource = CROSS_NODE
            branchCandidates = CROSS_CHOICES
            phase = .branchSelecting
            return
        }
        phase = .moving
        continueMove()
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
            if owner[t] == nil {
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
        return lv <= 0 ? 0 : (30 * lv)
    }
    
    func placeCreature(from card: Card, at tile: Int, by pid: Int) {
        let s = card.stats ?? CreatureStats.defaultLizard
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
        hp = hp
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
            let before = players[turn].gold
            let fee = toll(at: t)
            players[turn].gold = max(0, before - fee)
            battleResult = attackerIsCPU
                ? "通行料を奪った"
                : "通行料を奪われた\n\(before)→\(players[turn].gold)"
            canEndTurn = true
        } else {
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
        handleAfterMove()
    }
    
    // 既存の「次のマス」算出を利用して1歩進める
    private func advanceOneStep() {
        // まず通常の1歩前進
        let cur = players[turn].pos
        let next = nextIndex(for: turn, from: cur)
        players[turn].pos = next
        stepsLeft -= 1

//        // マス5に入り、まだ歩数が残っている場合の分岐
//        if players[turn].pos == CROSS_NODE, stepsLeft > 0 {
//            if turn == 0 {
//                // プレイヤー：UI停止（この時点では方向未確定）
//                branchSource = CROSS_NODE
//                branchCandidates = CROSS_CHOICES
//                phase = .branchSelecting
//                return
//            } else {
//                if let choice = CROSS_CHOICES.randomElement() {
//                    applyBranchChoice(choice) // ← これでCPU側だけのdirが更新される
//                }
//            }
//        }
        
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
}

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
    // 盤（5×5外周 = 16マス）
    let sideCount: Int = 5
    let tileCount: Int

    // マス占領状態
    @Published var owner: [Int?]      // nil=未占領, 0=You, 1=CPU
    @Published var level: [Int]       // 0=未設置, 設置時は1
    @Published var creatureSymbol: [String?] // "lizard.fill" など

    // プレイヤー
    @Published var players: [Player] = [
        Player(name: "You", pos: 0, gold: 500),
        Player(name: "CPU", pos: 0, gold: 500)
    ]
    @Published var turn: Int = 0                // 0=You, 1=CPU
    @Published var lastRoll: Int = 0
    @Published var phase: Phase = .ready        // .ready(前) → .rolled(後) → .moved(後処理)
    @Published var mustDiscardFor: Int? = nil   // 捨てる必要がある手番（0 or 1）: UI表示用

    enum Phase { case ready, rolled, moved }

    // デッキ＆手札
    private var decks: [[Card]] = [[], []]
    @Published var hands: [[Card]] = [[], []]

    // スペル効果：次のロールを1に固定
    private var forceRollToOneFor: [Bool] = [false, false]

    init() {
        self.tileCount = 4 * (sideCount - 1)   // ← まず tileCount を確定
        self.owner = Array(repeating: nil, count: tileCount)
        self.level = Array(repeating: 0, count: tileCount)
        self.creatureSymbol = Array(repeating: nil, count: tileCount)

        // デッキ生成（30枚：spell×10, creature×20）＆シャッフル
        for pid in 0...1 {
            var deck: [Card] = []
            // スペル10枚（全部「次回サイコロ=1」）
            for i in 1...10 {
                deck.append(Card(kind: .spell,    name: "固定1（S\(i))", symbol: "sun.max.fill"))
            }
            // クリーチャー20枚
            for i in 1...20 {
                deck.append(Card(kind: .creature, name: "トカゲ（C\(i))", symbol: "lizard.fill"))
            }
            decks[pid] = deck.shuffled()

            // 初期手札3枚
            for _ in 0..<3 { drawOne(for: pid) }
        }
        startTurnIfNeeded()
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

        if turn == 1 {
            // CPU自動行動
            runCpuAuto()
        }
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
        lastRoll = forceRollToOneFor[turn] ? 1 : Int.random(in: 1...6)
        forceRollToOneFor[turn] = false
        phase = .rolled
        // 自動移動
        moveCurrent()
    }

    private func wrap(_ n: Int) -> Int {
        (n % tileCount + tileCount) % tileCount
    }

    private func moveCurrent() {
        guard phase == .rolled else { return }
        players[turn].pos = wrap(players[turn].pos + lastRoll)
        phase = .moved
        // 移動後：手札使用が可能（UI側で制御）
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
            // 現在マスが未占領なら設置
            let t = players[0].pos
            guard owner[t] == nil else { return }
            consumeFromHand(card, for: 0)
            owner[t] = 0
            level[t] = 1
            creatureSymbol[t] = card.symbol
        }
    }

    private func consumeFromHand(_ card: Card, for pid: Int) {
        if let i = hands[pid].firstIndex(of: card) { hands[pid].remove(at: i) }
    }

    // MARK: - CPU 自動
    private func runCpuAuto() {
        // ちょっと間を置いて順に
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
            self.phase = .rolled
            self.players[1].pos = self.wrap(self.players[1].pos + self.lastRoll)
            self.phase = .moved

            // 移動後：空き地ならクリーチャーを1枚置く
            let t = self.players[1].pos
            if self.owner[t] == nil, let creature = self.hands[1].first(where: { $0.kind == .creature }) {
                self.consumeFromHand(creature, for: 1)
                self.owner[t] = 1
                self.level[t] = 1
                self.creatureSymbol[t] = creature.symbol
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
}

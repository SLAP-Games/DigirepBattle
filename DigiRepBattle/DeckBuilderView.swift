//
//  DeckBuilderView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/25.
//

import SwiftUI

/// デッキ編成画面でカード詳細を開いたときのソース
private enum DetailSource {
    case deck(id: CardID, kind: CardKind)
    case collection(id: CardID, kind: CardKind)
}

private enum CountEditMode {
    case add   // コレクション → デッキに追加
    case remove // デッキ → デッキから削除
}

struct CardEntry: Identifiable {
    let id: CardID
    let kind: CardKind
    let count: Int
    let sampleCard: Card
}

struct DeckBuilderView: View {

    @State private var collection: CardCollection
    let onStartBattle: (DeckList) -> Void
    @State private var decks: [DeckList]
    @State private var selectedDeckIndex: Int = 0
    private var currentDeckBinding: Binding<DeckList> {
        Binding(
            get: { decks[selectedDeckIndex] },
            set: { decks[selectedDeckIndex] = $0 }
        )
    }
    @State private var showingDetailCard: Card? = nil
    @State private var detailSource: DetailSource? = nil
    @State private var showCountPicker: Bool = false
    @State private var countEditMode: CountEditMode = .add
    @State private var countTargetID: CardID? = nil
    @State private var countTargetKind: CardKind = .creature
    @State private var countMax: Int = 1
    @State private var countValue: Int = 1
    @State private var alertMessage: String? = nil
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    init(collection: CardCollection,
         onStartBattle: @escaping (DeckList) -> Void) {
        _collection = State(initialValue: collection)
        self.onStartBattle = onStartBattle

        // ★ デッキ1だけ固定の初期デッキを入れておく
        let deck1 = DeckBuilderView.makeDeck1()
        let emptyDeck = DeckList()
        _decks = State(initialValue: [deck1, emptyDeck, emptyDeck])
    }

    var body: some View {
        ZStack {
            // 背景画像
            Image("backGround1")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack {
                        VStack(spacing: 8) {
                            deckArea
                                .frame(height: geo.size.height / 2)
                            
                            collectionArea
                                .frame(height: geo.size.height / 2)
                        }
                        VStack {
                            Spacer()
                            // 最下部：ボトムバー
                            bottomBar
                                .frame(height: geo.size.height / 10)
                        }
                    }
                }
                .padding(.top, 24)
            }
            .padding(.top, 16)
            .padding(.horizontal, 2)
            .padding(.bottom, 24)
            .foregroundColor(.white)
        }
        .overlay(detailOverlay)
        .overlay(countPickerOverlay)
        .alert(item: Binding(
            get: {
                alertMessage.map { AlertMessage(text: $0) }
            },
            set: { _ in alertMessage = nil }
        )) { msg in
            Alert(title: Text("注意"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            SoundManager.shared.playBGM(.deck)
        }
        .onDisappear {
            SoundManager.shared.stopBGM()
        }
    }
    
    /// デッキ1用の固定デッキ
    private static func makeDeck1() -> DeckList {
        var deck = DeckList()

        // クリーチャー
        deck.creatureSlots = [
            "cre-defaultLizard":        5,
            "cre-defaultCrocodile":    5,
            "cre-defaultTurtle":       5,
            "cre-defaultBeardedDragon":5,
            "cre-defaultHornedFrog":   5,
            "cre-defaultGreenIguana":  5,
            "cre-defaultBallPython":   5
        ]

        // スペル
        deck.spellSlots = [
            "sp-dice1":        1,
            "sp-dice2":        1,
            "sp-dice3":        1,
            "sp-dice4":        1,
            "sp-dice5":        1,
            "sp-dice6":        1,
            "sp-doubleDice":   1,
            "sp-firstStrike":  1,
            "sp-hardFang":     1,
            "sp-sharpFang":    2,
            "sp-poisonFang":   2,
            "sp-hardScale":    2,
            "sp-bigScale":     2,
            "sp-draw2":        2,
            "sp-deleteHand":   2,
            "sp-elixir":   2,
            "sp-decay":   2
        ]

        return deck
    }

    private var deckArea: some View {
        let deck = currentDeckBinding.wrappedValue

        return VStack(alignment: .leading, spacing: 6) {
            // デッキ切り替え & 枚数表示
            HStack {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { idx in
                        Button("\(idx + 1)") {
                            selectedDeckIndex = idx
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(idx == selectedDeckIndex ? Color.blue.opacity(0.8) : Color.black.opacity(0.4))
                        )
                    }
                }

                Spacer()

                Text("ク \(deck.totalCreatures)/\(DeckList.creatureLimit)  ス \(deck.totalSpells)/\(DeckList.spellLimit)")
                    .font(.footnote.weight(.bold))
            }

            // デッキカード一覧（4列グリッド）
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(deckEntries(deck: deck)) { entry in
                        CardView(card: entry.sampleCard, badgeCount: entry.count)
                            .onTapGesture {
                                openDetail(cardID: entry.id, kind: entry.kind, source: .deck(id: entry.id, kind: entry.kind))
                            }
                    }
                }
                .padding(6)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.25))
            )
        }
    }

    private var collectionArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("カードコレクション")
                .font(.headline)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(collectionEntries()) { entry in
                        CardView(card: entry.sampleCard, badgeCount: entry.count)
                            .onTapGesture {
                                openDetail(cardID: entry.id,
                                           kind: entry.kind,
                                           source: .collection(id: entry.id, kind: entry.kind))
                            }
                    }
                }
                .padding(6)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.25))
            )
        }
    }

    private var bottomBar: some View {
        let deck = currentDeckBinding.wrappedValue

        return HStack(spacing: 0) {
            // 未実装ボタン
            ZStack {
                Rectangle()
                    .fill(Color.black)

                Button("未実装") {
                    // TODO: 何か機能を入れる場合はここに
                }
                .buttonStyle(.plain) // ← 余計な内側パディングを消す
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // バトル開始ボタン
            ZStack {
                Rectangle()
                    .fill(Color.red)

                Button("バトル開始") {
                    if deck.totalCreatures == DeckList.creatureLimit &&
                        deck.totalSpells == DeckList.spellLimit {
                        onStartBattle(deck)
                    } else {
                        alertMessage = "デッキ枚数が不足しています。\nク \(deck.totalCreatures)/\(DeckList.creatureLimit)  ス \(deck.totalSpells)/\(DeckList.spellLimit)"
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 戻るボタン
            ZStack {
                Rectangle()
                    .fill(Color.black)

                Button("戻る") {
                    // TODO: 戻る処理
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .font(.headline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    /// デッキ内のユニークカード一覧（枚数付き）
    private func deckEntries(deck: DeckList) -> [CardEntry] {
        var result: [CardEntry] = []

        for (id, count) in deck.creatureSlots {
            if let def = CardDatabase.definition(for: id) {
                result.append(
                    CardEntry(id: id, kind: .creature, count: count, sampleCard: def.makeInstance())
                )
            }
        }
        for (id, count) in deck.spellSlots {
            if let def = CardDatabase.definition(for: id) {
                result.append(
                    CardEntry(id: id, kind: .spell, count: count, sampleCard: def.makeInstance())
                )
            }
        }

        return result.sorted { $0.id < $1.id }
    }

    /// コレクション内のユニークカード一覧（「残り枚数」付き）
    private func collectionEntries() -> [CardEntry] {
        let deck = currentDeckBinding.wrappedValue
        var result: [CardEntry] = []

        for (id, ownedCount) in collection.owned {
            guard let def = CardDatabase.definition(for: id) else { continue }
            let sample = def.makeInstance()
            let kind = sample.kind

            // 現在デッキで使用中の枚数
            let usedInDeck: Int
            switch kind {
            case .creature:
                usedInDeck = deck.creatureSlots[id] ?? 0
            case .spell:
                usedInDeck = deck.spellSlots[id] ?? 0
            }

            // 残り枚数 = 所持 − デッキで使用中
            let remaining = max(ownedCount - usedInDeck, 0)

            result.append(
                CardEntry(
                    id: id,
                    kind: kind,
                    count: remaining,
                    sampleCard: sample
                )
            )
        }

        return result.sorted { $0.id < $1.id }
    }

    private var detailOverlay: some View {
        Group {
            if let card = showingDetailCard,
               let source = detailSource {

                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { closeDetail() }

                    VStack(spacing: 12) {
                        // CardDetailOverlay と同じような見た目を reuse
                        CardDetailSimple(card: card)

                        HStack(spacing: 12) {
                            switch source {
                            case .deck(let id, let kind):
                                Button("削除") {
                                    startCountEdit(id: id, kind: kind, mode: .remove)
                                }
                                .buttonStyle(.borderedProminent)

                            case .collection(let id, let kind):
                                Button("追加") {
                                    startCountEdit(id: id, kind: kind, mode: .add)
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            Button("閉じる") {
                                closeDetail()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                    )
                    .padding(24)
                }
            }
        }
        .animation(.easeInOut, value: showingDetailCard != nil)
    }

    private func openDetail(cardID: CardID,
                            kind: CardKind,
                            source: DetailSource) {
        guard let def = CardDatabase.definition(for: cardID) else { return }
        showingDetailCard = def.makeInstance()
        detailSource = source
    }

    private func closeDetail() {
        showingDetailCard = nil
        detailSource = nil
    }

    // MARK: - Count Picker Overlay

    private var countPickerOverlay: some View {
        Group {
            if showCountPicker,
               let targetID = countTargetID {

                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text(countEditMode == .add ? "追加する枚数" : "削除する枚数")
                            .font(.headline)

                        Stepper(value: $countValue, in: 1...countMax) {
                            Text("\(countValue) 枚")
                        }
                        .padding()

                        HStack(spacing: 12) {
                            Button("OK") {
                                applyCountChange(id: targetID,
                                                 kind: countTargetKind,
                                                 mode: countEditMode,
                                                 delta: countValue)
                                showCountPicker = false
                            }
                            .buttonStyle(.borderedProminent)

                            Button("キャンセル") {
                                showCountPicker = false
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                    )
                    .padding(40)
                }
            }
        }
        .animation(.easeInOut, value: showCountPicker)
    }

    private func startCountEdit(id: CardID,
                                kind: CardKind,
                                mode: CountEditMode) {
        let deck = currentDeckBinding.wrappedValue
        countEditMode = mode
        countTargetID = id
        countTargetKind = kind

        switch mode {
        case .add:
            let current = (kind == .creature ? deck.creatureSlots[id] : deck.spellSlots[id]) ?? 0
            let owned = collection.count(of: id)
            let maxByOwned = max(owned - current, 0)

            // 上限は「所持枚数 - 現在デッキに入っている枚数」と
            // デッキの残り枠の小さい方
            let limitByDeck: Int
            if kind == .creature {
                limitByDeck = max(DeckList.creatureLimit - deck.totalCreatures, 0)
            } else {
                limitByDeck = max(DeckList.spellLimit - deck.totalSpells, 0)
            }

            countMax = max(1, min(maxByOwned, limitByDeck))
            countValue = 1

        case .remove:
            let current = (kind == .creature ? deck.creatureSlots[id] : deck.spellSlots[id]) ?? 0
            countMax = max(1, current)
            countValue = 1
        }

        showCountPicker = true
    }

    private func applyCountChange(id: CardID,
                                  kind: CardKind,
                                  mode: CountEditMode,
                                  delta: Int) {
        guard delta > 0 else { return }

        var deck = currentDeckBinding.wrappedValue
        let current = (kind == .creature ? deck.creatureSlots[id] : deck.spellSlots[id]) ?? 0

        let newCount: Int
        switch mode {
        case .add:
            newCount = current + delta
        case .remove:
            newCount = max(current - delta, 0)
        }

        guard deck.canSetCount(for: id, kind: kind, to: newCount, collection: collection) else {
            alertMessage = "枚数の上限または所持枚数を超えています。"
            return
        }

        deck.setCount(for: id, kind: kind, count: newCount)
        currentDeckBinding.wrappedValue = deck
    }
}

// MARK: - 簡易 Alert 用

private struct AlertMessage: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - CardDetail の簡易版（外見だけ流用）

/// GameVM などに依存しない、デッキ編成専用のシンプルなカード詳細
struct CardDetailSimple: View {
    let card: Card

    var body: some View {
        VStack(spacing: 8) {
            Text(card.name)
                .font(.system(size: 26, weight: .semibold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(.primary)
                .frame(maxWidth: 430)
                .padding(.horizontal, 20)

            // ここでは簡単に大型の CardView を利用
            CardView(card: card)
                .frame(width: 140, height: 200)

            // 必要に応じてステータステキストなど追加
            if let stats = card.stats {
                Text("HP \(stats.hpMax)  POW \(stats.power)  DUR \(stats.durability)")
                    .font(.footnote)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    DeckBuilderView(collection: CardCollection(), onStartBattle: { _ in })
}

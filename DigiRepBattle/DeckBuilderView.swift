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
    let onStartBattle: (DeckList, BattleDifficulty) -> Void
    @State private var decks: [DeckList]
    @State private var selectedDeckIndex: Int = 0
    @State private var selectedDifficulty: BattleDifficulty = .intermediate
    @State private var showDifficultyDialog: Bool = false
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
         onStartBattle: @escaping (DeckList, BattleDifficulty) -> Void) {
        _collection = State(initialValue: collection)
        self.onStartBattle = onStartBattle

        // ★ デッキ1だけ固定の初期デッキを入れておく
        let deck1 = DeckList.defaultBattleDeck
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
        .confirmationDialog("難易度を選択", isPresented: $showDifficultyDialog, titleVisibility: .visible) {
            ForEach(BattleDifficulty.allCases) { diff in
                Button(diff.displayName) {
                    selectedDifficulty = diff
                }
            }
        }
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
    }
    
    private var deckArea: some View {
        let deck = currentDeckBinding.wrappedValue

        return VStack(alignment: .leading, spacing: 6) {
            // デッキ切り替え & 枚数表示
            HStack(spacing: 8) {
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
                    .font(.bestTenFootnote)
                    .bold()
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
                .font(.bestTenHeadline)

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

                Button("難易度") {
                    showDifficultyDialog = true
                }
                .buttonStyle(.plain) // ← 余計な内側パディングを消す
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // バトル開始ボタン
            ZStack {
                Rectangle()
                    .fill(Color.red)

                Button("バトル開始\n（\(selectedDifficulty.displayName)）") {
                    if deck.totalCreatures == DeckList.creatureLimit &&
                        deck.totalSpells == DeckList.spellLimit {
                        SoundManager.shared.playStartSound()
                        onStartBattle(deck, selectedDifficulty)
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
        .font(.bestTenHeadline)
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

                    DeckBuilderCardDetailOverlay(
                        card: card,
                        actionTitle: {
                            switch source {
                            case .deck:
                                return "削除"
                            case .collection:
                                return "追加"
                            }
                        }(),
                        onPrimary: {
                            switch source {
                            case .deck(let id, let kind):
                                startCountEdit(id: id, kind: kind, mode: .remove)
                            case .collection(let id, let kind):
                                startCountEdit(id: id, kind: kind, mode: .add)
                            }
                        },
                        onClose: { closeDetail() },
                        spellDescription: spellDescription(for:)
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
    
    private func spellDescription(for card: Card) -> String {
        guard let effect = card.spell else {
            return ""
        }
        switch effect {
        case .fixNextRoll(let n):
            return "次の出目を \(n) に固定"
        case .doubleDice:
            return "次のターン、サイコロを2つ振る"
        case .buffPower(let n):
            return "戦闘中、戦闘力を \(n) 上昇"
        case .buffDefense(let n):
            return "戦闘中、耐久力を \(n) 上昇"
        case .firstStrike:
            return "戦闘中、先に攻撃を行う"
        case .poison:
            return "毎ターンHPの20%の毒ダメージを付与"
        case .reflectSkill:
            return "敵の特殊スキルを跳ね返す"
        case .teleport:
            return "任意のマスへワープする"
        case .healHP(let n):
            return "HPを \(n) 回復する"
        case .drawCards(let n):
            return "手札を \(n) 枚引く"
        case .discardOpponentCards(let n):
            return "相手の手札を \(n) 枚削除"
        case .fullHealAnyCreature:
            return "デジレプのHPを全回復させる"
        case .changeLandLevel:
            return "任意の土地のレベルを1下げる"
        case .setLandTollZero:
            return "任意の土地の通行料を0にする"
        case .multiplyLandToll:
            return "任意の土地の通行料を2倍にする"
        case .damageAnyCreature(let n):
            return "デジレプに \(n) ダメージを与える"
        case .poisonAnyCreature:
            return "デジレプを毒状態にする"
        case .cleanseTileStatus:
            return "土地にかかっている効果を解除する"
        case .gainGold(let n):
            return "\(n)Gを獲得する"
        case .stealGold(let n):
            return "相手から \(n)G 奪い、自分のGOLDに加える"
        case .inspectCreature:
            return "相手デジレプのステータスを確認できる"
        case .aoeDamageByResist(let category, _, let n):
            let label: String
            switch category {
            case .dry:   label = "乾耐性"
            case .water: label = "水耐性"
            case .heat:  label = "熱耐性"
            case .cold:  label = "冷耐性"
            }
            return "全デジレプに対し \(label)8未満で \(n) 、8以上で \(n) - (耐性×3) ダメージ"
        case .changeTileAttribute(let kind):
            let label: String
            switch kind {
            case .normal: label = "草原"
            case .dry:    label = "砂漠"
            case .water:  label = "水辺"
            case .heat:   label = "火山"
            case .cold:   label = "雪山"
            }
            return "任意の土地を \(label) に変える"
        case .purgeAllCreatures:
            return "自軍を含む全てのデジレプを削除する"
        }
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
                            .font(.bestTenHeadline)

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
                            .buttonStyle(.borderedProminent)
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

// MARK: - DeckBuilder 用 Card Detail

private struct DeckBuilderCardDetailOverlay: View {
    let card: Card
    let actionTitle: String
    let onPrimary: () -> Void
    let onClose: () -> Void
    let spellDescription: (Card) -> String

    @State private var appearOpacity: Double = 0
    @State private var appearOffsetY: CGFloat = 50
    @State private var spinAngle: Double = 0
    private let cardSize = CGSize(width: 260, height: 360)

    private let frameImageName = "cardL"
    private let backImageName  = "cardLreverse"

    var body: some View {
        VStack(spacing: 14) {
            Text(card.name)
                .font(.bestTen(size: 22))
                .fontWeight(.semibold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(.white)
                .frame(maxWidth: 320)
                .padding(.horizontal, 20)

            CardFlipDisplay(
                card: card,
                angle: $spinAngle,
                frameImageName: frameImageName,
                backImageName: backImageName,
                spellDescription: spellDescription
            )
            .frame(width: cardSize.width, height: cardSize.height)

            HStack(spacing: 12) {
                Button(actionTitle) {
                    onPrimary()
                }
                .buttonStyle(.borderedProminent)

                Button("閉じる") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: 360)
        .shadow(radius: 16)
        .opacity(appearOpacity)
        .offset(y: appearOffsetY)
        .onAppear {
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
            appearOpacity = 0
            appearOffsetY = 50
            spinAngle = 0
        }
    }
}

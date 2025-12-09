//
//  CardDatabase.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/16.
//

import Foundation

struct CardDefinition {
    let id: CardID
    let kind: CardKind
    let name: String
    let symbol: String
    let stats: CreatureStats?
    let spellEffect: SpellEffect?
    let cost: Int

    func makeInstance() -> Card {
        Card(
            id: id,
            kind: kind,
            name: name,
            symbol: symbol,
            cost: cost,
            stats: stats,
            spell: spellEffect
        )
    }
}

extension CardDefinition {
    static func creature(
        id: CardID,
        name: String,
        symbol: String,
        stats: CreatureStats,
        cost: Int = 0
    ) -> CardDefinition {
        CardDefinition(
            id: id,
            kind: .creature,
            name: name,
            symbol: symbol,
            stats: stats,
            spellEffect: nil,
            cost: cost
        )
    }

    static func spell(
        id: CardID,
        name: String,
        symbol: String,
        effect: SpellEffect,
        cost: Int
    ) -> CardDefinition {
        CardDefinition(
            id: id,
            kind: .spell,
            name: name,
            symbol: symbol,
            stats: nil,
            spellEffect: effect,
            cost: cost
        )
    }
}

enum CardDatabase {
    static let all: [CardID: CardDefinition] = [
//----------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　クリーチャー
//----------------------------------------------------------------------------
        "cre-defaultLizard": .creature(
            id: "cre-defaultLizard",
            name: "デジトカゲ",
            symbol: "defaultLizard",
            stats: .defaultLizard
        ),
        "cre-defaultGecko": .creature(
            id: "cre-defaultGecko",
            name: "デジヤモリ",
            symbol: "defaultGecko",
            stats: .defaultGecko
        ),
        "cre-defaultCrocodile": .creature(
            id: "cre-defaultCrocodile",
            name: "デジワニ",
            symbol: "defaultCrocodile",
            stats: .defaultCrocodile
        ),

        "cre-defaultSnake": .creature(
            id: "cre-defaultSnake",
            name: "デジヘビ",
            symbol: "defaultSnake",
            stats: .defaultSnake
        ),

        "cre-defaultIguana": .creature(
            id: "cre-defaultIguana",
            name: "デジイグアナ",
            symbol: "defaultIguana",
            stats: .defaultIguana
        ),

        "cre-defaultTurtle": .creature(
            id: "cre-defaultTurtle",
            name: "デジガメ",
            symbol: "defaultTurtle",
            stats: .defaultTurtle
        ),

        "cre-defaultFrog": .creature(
            id: "cre-defaultFrog",
            name: "デジガエル",
            symbol: "defaultFrog",
            stats: .defaultFrog
        ),

        "cre-defaultBeardedDragon": .creature(
            id: "cre-defaultBeardedDragon",
            name: "デジフトアゴ",
            symbol: "defaultBeardedDragon",
            stats: .defaultBeardedDragon
        ),

        "cre-defaultLeopardGecko": .creature(
            id: "cre-defaultLeopardGecko",
            name: "デジレオパ",
            symbol: "defaultLeopardGecko",
            stats: .defaultLeopardGecko
        ),

        "cre-defaultNileCrocodile": .creature(
            id: "cre-defaultNileCrocodile",
            name: "デジクロコ",
            symbol: "defaultNileCrocodile",
            stats: .defaultNileCrocodile
        ),

        "cre-defaultBallPython": .creature(
            id: "cre-defaultBallPython",
            name: "デジパイソン",
            symbol: "defaultBallPython",
            stats: .defaultBallPython
        ),

        "cre-defaultGreenIguana": .creature(
            id: "cre-defaultGreenIguana",
            name: "デジグリーン",
            symbol: "defaultGreenIguana",
            stats: .defaultGreenIguana
        ),

        "cre-defaultaStarTurtle": .creature(
            id: "cre-defaultaStarTurtle",
            name: "デジホシガメ",
            symbol: "defaultaStarTurtle",
            stats: .defaultaStarTurtle
        ),

        "cre-defaultHornedFrog": .creature(
            id: "cre-defaultHornedFrog",
            name: "デジツノガエル",
            symbol: "defaultHornedFrog",
            stats: .defaultHornedFrog
        ),
//----------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　スペル
//----------------------------------------------------------------------------
        "sp-dice1": .spell(
            id: "sp-dice1",
            name: "ダイス1",
            symbol: "dice1",
            effect: .fixNextRoll(1),
            cost: 20
        ),
        "sp-dice2": .spell(
            id: "sp-dice2",
            name: "ダイス2",
            symbol: "dice2",
            effect: .fixNextRoll(2),
            cost: 20
        ),
        "sp-dice3": .spell(
            id: "sp-dice3",
            name: "ダイス3",
            symbol: "dice3",
            effect: .fixNextRoll(3),
            cost: 20
        ),
        "sp-dice4": .spell(
            id: "sp-dice4",
            name: "ダイス4",
            symbol: "dice4",
            effect: .fixNextRoll(4),
            cost: 20
        ),
        "sp-dice5": .spell(
            id: "sp-dice5",
            name: "ダイス5",
            symbol: "dice5",
            effect: .fixNextRoll(5),
            cost: 20
        ),
        "sp-dice6": .spell(
            id: "sp-dice6",
            name: "ダイス6",
            symbol: "dice6",
            effect: .fixNextRoll(6),
            cost: 20
        ),

        // --- ダブルダイス / 先制 ---
        "sp-doubleDice": .spell(
            id: "sp-doubleDice",
            name: "ダブルダイス",
            symbol: "doubleDice",
            effect: .doubleDice,
            cost: 30
        ),
        "sp-firstStrike": .spell(
            id: "sp-firstStrike",
            name: "先制",
            symbol: "firstStrike",
            effect: .firstStrike,
            cost: 30
        ),

        // --- 牙系（攻撃力） ---
        "sp-hardFang": .spell(
            id: "sp-hardFang",
            name: "硬牙",
            symbol: "hardFang",
            effect: .buffPower(10),
            cost: 20
        ),
        "sp-sharpFang": .spell(
            id: "sp-sharpFang",
            name: "鋭牙",
            symbol: "sharpFang",
            effect: .buffPower(20),
            cost: 40
        ),
        "sp-poisonFang": .spell(
            id: "sp-poisonFang",
            name: "毒牙",
            symbol: "poisonFang",
            effect: .poison,
            cost: 60
        ),

        // --- 鱗系（防御力） ---
        "sp-bigScale": .spell(
            id: "sp-bigScale",
            name: "大鱗",
            symbol: "bigScale",
            effect: .buffDefense(10),
            cost: 20
        ),
        "sp-hardScale": .spell(
            id: "sp-hardScale",
            name: "硬鱗",
            symbol: "hardScale",
            effect: .buffDefense(20),
            cost: 40
        ),
        "sp-reflectScale": .spell(
            id: "sp-reflectScale",
            name: "反射鱗",
            symbol: "reflectScale",
            effect: .reflectSkill,
            cost: 60
        ),

        // --- 手札操作 ---
        "sp-draw2": .spell(
            id: "sp-draw2",
            name: "ドロー2",
            symbol: "draw2",
            effect: .drawCards(2),
            cost: 30
        ),
        "sp-deleteHand": .spell(
            id: "sp-deleteHand",
            name: "削除",
            symbol: "deleteHand",
            effect: .discardOpponentCards(1),
            cost: 30
        ),

        // --- クリーチャー / 土地操作 ---
        "sp-elixir": .spell(
            id: "sp-elixir",
            name: "秘薬",
            symbol: "elixir",
            effect: .fullHealAnyCreature,
            cost: 50
        ),
        "sp-decay": .spell(
            id: "sp-decay",
            name: "腐敗",
            symbol: "decay",
            effect: .changeLandLevel(delta: -1),
            cost: 30
        ),
        "sp-devastation": .spell(
            id: "sp-devastation",
            name: "荒廃",
            symbol: "devastation",
            effect: .setLandTollZero,
            cost: 100
        ),
        "sp-harvest": .spell(
            id: "sp-harvest",
            name: "豊作",
            symbol: "harvest",
            effect: .multiplyLandToll(2.0),
            cost: 100
        ),
        "sp-greatStorm": .spell(
            id: "sp-greatStorm",
            name: "大嵐",
            symbol: "greatStorm",
            effect: .damageAnyCreature(40),
            cost: 50
        ),
        "sp-disaster": .spell(
            id: "sp-disaster",
            name: "落雷",
            symbol: "disaster",
            effect: .damageAnyCreature(80),
            cost: 150
        ),
        "sp-poisonSmoke": .spell(
            id: "sp-poisonSmoke",
            name: "毒煙",
            symbol: "poisonSmoke",
            effect: .poisonAnyCreature,
            cost: 100
        ),
        "sp-cure": .spell(
            id: "sp-cure",
            name: "浄化",
            symbol: "cure",
            effect: .cleanseTileStatus,
            cost: 100
        ),

        // --- GOLD ---
        "sp-treasure": .spell(
            id: "sp-treasure",
            name: "財宝",
            symbol: "treasure",
            effect: .gainGold(500),
            cost: 100
        ),
        "sp-plunder": .spell(
            id: "sp-plunder",
            name: "略奪",
            symbol: "plunder",
            effect: .stealGold(200),
            cost: 100
        ),

        // --- 情報系 ---
        "sp-clairvoyance": .spell(
            id: "sp-clairvoyance",
            name: "透視",
            symbol: "clairvoyance",
            effect: .inspectCreature,
            cost: 50
        ),

        // --- 耐性条件つき全体攻撃 ---
        "sp-blizzard": .spell(
            id: "sp-blizzard",
            name: "吹雪",
            symbol: "blizzard",
            effect: .aoeDamageByResist(
                category: .cold,
                threshold: 10,
                amount: 50
            ),
            cost: 200
        ),
        "sp-eruption": .spell(
            id: "sp-eruption",
            name: "噴火",
            symbol: "eruption",
            effect: .aoeDamageByResist(
                category: .heat,
                threshold: 10,
                amount: 50
            ),
            cost: 200
        ),
        "sp-heavyRain": .spell(
            id: "sp-heavyRain",
            name: "豪雨",
            symbol: "heavyRain",
            effect: .aoeDamageByResist(
                category: .water,
                threshold: 10,
                amount: 50
            ),
            cost: 200
        ),
        "sp-drought": .spell(
            id: "sp-drought",
            name: "干魃",
            symbol: "drought",
            effect: .aoeDamageByResist(
                category: .dry,
                threshold: 10,
                amount: 50
            ),
            cost: 200
        ),

        // --- マス属性変更 ---
        "sp-snowMountain": .spell(
            id: "sp-snowMountain",
            name: "雪山",
            symbol: "snowMountain",
            effect: .changeTileAttribute(.cold),
            cost: 30
        ),
        "sp-desert": .spell(
            id: "sp-desert",
            name: "砂漠",
            symbol: "desert",
            effect: .changeTileAttribute(.dry),
            cost: 30
        ),
        "sp-volcano": .spell(
            id: "sp-volcano",
            name: "火山",
            symbol: "volcano",
            effect: .changeTileAttribute(.heat),
            cost: 30
        ),
        "sp-jungle": .spell(
            id: "sp-jungle",
            name: "雨林",
            symbol: "jungle",
            effect: .changeTileAttribute(.water),
            cost: 30
        ),

        // --- バグ ---
        "sp-purification": .spell(
            id: "sp-purification",
            name: "バグ",
            symbol: "purification",
            effect: .purgeAllCreatures,
            cost: 500
        )
    ]

    static func definition(for id: CardID) -> CardDefinition? {
        all[id]
    }
}

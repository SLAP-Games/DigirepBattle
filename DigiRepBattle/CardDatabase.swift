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

    func makeInstance() -> Card {
        Card(
            id: id,
            kind: kind,
            name: name,
            symbol: symbol,
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
        stats: CreatureStats
    ) -> CardDefinition {
        CardDefinition(
            id: id,
            kind: .creature,
            name: name,
            symbol: symbol,
            stats: stats,
            spellEffect: nil
        )
    }

    static func spell(
        id: CardID,
        name: String,
        symbol: String,
        effect: SpellEffect
    ) -> CardDefinition {
        CardDefinition(
            id: id,
            kind: .spell,
            name: name,
            symbol: symbol,
            stats: nil,
            spellEffect: effect
        )
    }
}

enum CardDatabase {
    static let all: [CardID: CardDefinition] = [
        // クリーチャー
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
        // スペル
        "sp-fireball": .spell(
            id: "sp-fireball",
            name: "ファイアボール",
            symbol: "🔥",
            effect: .buffPower(5)
        )
    ]

    static func definition(for id: CardID) -> CardDefinition? {
        all[id]
    }
}

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
                // ── 上：ボード（右上にCPUバッジ） ──
                ZStack(alignment: .topTrailing) {
                    RingBoardView(
                        p1Pos: vm.players[0].pos,
                        p2Pos: vm.players[1].pos,
                        owner: vm.owner,
                        level: vm.level,
                        creatureSymbol: vm.creatureSymbol,
                        toll: vm.toll
                    )
                    .frame(height: boardH)
                    .background {
                        Image("backGround1")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }

                    Badge(player: vm.players[1], active: vm.turn == 1, tint: .red)
                        .padding(.top, 10)
                        .padding(.trailing, 12)
                }

                // ── 下：操作エリア（自プレイヤー専用） ──
                ZStack {
                    Color.white
                    HStack(alignment: .top, spacing: 12) {
                        // 左：自分バッジの「下に縦並び」でRoll/End/Roll値
                        VStack(alignment: .leading, spacing: 8) {
                            Badge(player: vm.players[0], active: vm.turn == 0, tint: .blue)

                            VStack(alignment: .leading, spacing: 6) {
                                Button("🎲 Roll") { vm.rollDice() }
                                    .disabled(!(vm.turn == 0 && vm.phase == .ready && vm.mustDiscardFor == nil))

                                Button("✅ End") { vm.endTurn() }
                                    .disabled(!(vm.turn == 0 && vm.phase == .moved))

                                Text("Roll: \(vm.lastRoll)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Divider().frame(height: controlsH * 0.8)

                        // 右：手札（横並び）— 状況に応じて使用可否
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vm.hands[0]) { card in
                                    CardView(card: card)
                                        .overlay(
                                            Group {
                                                if vm.mustDiscardFor == 0 {
                                                    // 捨てフェーズ
                                                    Button("捨てる") { vm.discard(card, for: 0) }
                                                        .buttonStyle(.borderedProminent)
                                                        .padding(6)
                                                } else if vm.turn == 0 {
                                                    // 使用フェーズ
                                                    if vm.phase == .ready && card.kind == .spell {
                                                        Button("使う") { vm.useSpellPreRoll(card) }
                                                            .buttonStyle(.borderedProminent)
                                                            .padding(6)
                                                    } else if vm.phase == .moved {
                                                        Button("使う") { vm.useCardAfterMove(card) }
                                                            .buttonStyle(.borderedProminent)
                                                            .padding(6)
                                                    }
                                                }
                                            },
                                            alignment: .bottom
                                        )
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: controlsH * 0.9)
                    }
                    .padding(.horizontal)
                }
                .frame(height: controlsH)
                .overlay(Divider(), alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct Badge: View {
    let player: Player
    let active: Bool
    let tint: Color
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name).bold()
                Text("Gold: \(player.gold)").font(.caption)
            }
        }
        .padding(8)
        .background(active ? tint.opacity(0.15) : .white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CardView: View {
    let card: Card
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.secondary.opacity(0.5), lineWidth: 1)
                )
                .frame(width: 90, height: 130)

            VStack(spacing: 6) {
                Image(systemName: card.symbol)
                    .font(.system(size: 30))
                Text(card.kind == .spell ? "スペル" : "クリーチャー")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(card.name)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: 80)
            }
            .padding(6)
        }
    }
}

#Preview {
    ContentView()
}

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
                ZStack(alignment: .center) {
                    RingBoardView(
                        p1Pos: vm.players[0].pos,
                        p2Pos: vm.players[1].pos,
                        owner: vm.owner,
                        level: vm.level,
                        creatureSymbol: vm.creatureSymbol,
                        toll: vm.toll,
                        hp: vm.hp,
                        hpMax: vm.hpMax,
                        branchSource: vm.branchSource,
                        branchCandidates: vm.branchCandidates,
                        onPickBranch: { vm.pickBranch($0) },
                        onTapTile: { vm.tapTileForInspect($0) },
                        focusTile: vm.focusTile
                    )
                    .frame(height: boardH)
                    .background {
                        Image("backGround1")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }
                    .overlay(
                        Badge(player: vm.players[1], active: vm.turn == 1, tint: .red)
                            .padding(.top, 10)
                            .padding(.trailing, 12)
                            .allowsHitTesting(false),      // ← 盤面タップを邪魔しない
                        alignment: .topTrailing
                    )
                    // ★ ここで貼る：プレイヤーバッジ（左下）
                    .overlay(
                        Badge(player: vm.players[0], active: vm.turn == 0, tint: .blue)
                            .padding(.bottom, 10)
                            .padding(.leading, 12)
                            .allowsHitTesting(false),
                        alignment: .bottomLeading
                    )
                    
                    if vm.showCheckpointOverlay {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text(vm.checkpointMessage ?? "チェックポイント通過")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                                Button("閉じる") {
                                    vm.closeCheckpointOverlay()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(radius: 8)
                            )
                            .padding()
                        }
                        .transition(.opacity)
                        .zIndex(999) // 最前面に
                    }
                    
                    if let idx = vm.inspectTarget,
                       let iv = vm.makeInspectView(for: idx, viewer: 0) { // 0 = You
                        CreatureInfoPanel(iv: iv, onClose: { vm.closeInspect() })
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .zIndex(10)
                    }
                    
                    if let sheet = vm.activeSpecialSheet {
                        // 半透明の背面
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { vm.activeSpecialSheet = nil } // 背面タップで閉じる

                        // 中央カード
                        Group {
                            switch sheet {
                            case .levelUp(let tile):
                                PopupCard {
                                    LevelUpSheetView(vm: vm, tile: tile)
                                }
                            case .moveFrom(let tile):
                                PopupCard {
                                    MoveCreatureSheetView(vm: vm, fromTile: tile)
                                }
                            case .buySpell:
                                PopupCard {
                                    PurchaseSpellSheetView(vm: vm)
                                }
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: vm.activeSpecialSheet)
                    }
                }

                // ── 下：操作エリア（自プレイヤー専用） ──
                ZStack {
                    Color.white
                    HStack(alignment: .top, spacing: 12) {
                        // 左：自分バッジの「下に縦並び」でRoll/End/Roll値
                        VStack(alignment: .leading, spacing: 8) {

                            VStack(alignment: .leading, spacing: 6) {
                                Button("🎲 Roll") { vm.rollDice() }
                                    .disabled(!(vm.turn == 0 && vm.phase == .ready && vm.mustDiscardFor == nil))

                                Button("✅ End") { vm.endTurn() }
                                    .disabled(!(vm.turn == 0 && vm.phase == .moved))
                                    .disabled(!vm.canEndTurn)

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
                                                } else if vm.phase == .ready && card.kind == .spell {
                                                    Button("使う") { vm.useSpellPreRoll(card) }
                                                        .buttonStyle(.borderedProminent)
                                                        .padding(6)
                                                } else if vm.turn == 0, vm.phase == .moved {
                                                    if vm.expectBattleCardSelection && card.kind == .creature {
                                                        Button("戦闘") { vm.startBattle(with: card) }
                                                            .buttonStyle(.borderedProminent)
                                                            .padding(6)
                                                    } else {
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
                    
                    if vm.showSpecialMenu {
                        ZStack{
                            Color.yellow
                            SpecialNodeMenu(
                                kind: vm.currentSpecialKind,
                                levelUp: { vm.actionLevelUpOnSpecialNode() },
                                moveCreature: { vm.actionMoveCreatureFromSpecialNode() },
                                buySkill: { vm.actionPurchaseSkillOnSpecialNode() },
                                endTurn: {
                                    vm.endTurn()
                                }
                            )
                            .frame(height: controlsH)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    // バトル選択プロンプト（自分が相手マスに止まった直後）
                    if let t = vm.landedOnOpponentTileIndex,
                       vm.turn == 0, vm.phase == .moved, !vm.expectBattleCardSelection {
                        ZStack{
                            Color.yellow
                            HStack(spacing: 12) {
                                Text("相手のマス（\(t+1)）です。どうする？").bold()
                                Button("戦闘する") { vm.chooseBattle() }
                                    .buttonStyle(.borderedProminent)
                                Button("戦闘しない（通行料を払う）") { vm.payTollAndEndChoice() }
                                    .buttonStyle(.bordered)
                            }
                            .padding(8)
                            .background(.yellow.opacity(1))
                        }
                        
                    }
                    if let text = vm.battleResult {
                        ZStack {
                            Color.yellow
                                .onTapGesture { vm.battleResult = nil }

                            VStack(spacing: 12) {
                                Text(text)
                                    .multilineTextAlignment(.center)
                                    .font(.title3.bold())
                                    .padding(.vertical, 4)

                                Button("閉じる") { vm.battleResult = nil }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(radius: 10)
                        }
                        .zIndex(1000)
                    }
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
        .background(active ? .white.opacity(0.8) : .white.opacity(0.15))
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
                Image(card.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
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

struct SpecialNodeMenu: View {
    let kind: SpecialNodeKind?
    let levelUp: () -> Void
    let moveCreature: () -> Void
    let buySkill: () -> Void
    let endTurn: () -> Void

    var title: String {
        switch kind {
        case .some(.castle): return "城（特別マス）"
        case .some(.tower):  return "塔（特別マス）"
        case .none:          return "特別マス"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(spacing: 12) {
                Button("マスレベルUP", action: levelUp)
                    .buttonStyle(.borderedProminent)

                Button("クリーチャー移動", action: moveCreature)
                    .buttonStyle(.bordered)

                Button("スキル購入", action: buySkill)
                    .buttonStyle(.bordered)

                Button("ターン終了", action: endTurn)
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/10/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: GameVM
    @Environment(\.dismiss) private var dismiss
    @State private var isFadingOut: Bool = false
    var onBattleEnded: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let controlRatio: CGFloat = 0.25
            let controlsH = geo.size.height * controlRatio
            let boardH = geo.size.height - controlsH

            ZStack {
                VStack(spacing: 0) {
// -------------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　　　上部：ボードエリア
// -------------------------------------------------------------------------------
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
                        highlightTargets: vm.branchLandingTargets,
                        terrains: vm.terrain,
                        branchSource: vm.branchSource,
                        branchCandidates: vm.branchCandidates,
                        onPickBranch: { vm.pickBranch($0) },
                        onTapTile: { idx in
                            if vm.isForcedSaleMode && vm.turn == 0 {
                                vm.requestSell(tile: idx)
                            } else {
                                vm.tapTileForInspect(idx)
                            }
                        },
                        focusTile: vm.focusTile,
                        isHealingAnimating: vm.isHealingAnimating,
                        healingAmounts: vm.healingAmounts,
                        spellEffectTile: vm.spellEffectTile,
                        spellEffectKind: vm.spellEffectKind,
                        plunderEffectTile: vm.plunderEffectTile,
                        plunderEffectTrigger: vm.plunderEffectTrigger,
                        npcShakeActive: vm.npcShakeActive,
                        forceCameraFocus: vm.forceCameraFocus,
                        tileRemovalEffectTile: vm.tileRemovalEffectTile,
                        tileRemovalEffectTrigger: vm.tileRemovalEffectTrigger,
                        levelUpEffectTile: vm.levelUpEffectTile,
                        levelUpEffectTrigger: vm.levelUpEffectTrigger,
                        homeArrivalTile: vm.homeArrivalTile,
                        homeArrivalTrigger: vm.homeArrivalTrigger
                    )
                    .frame(height: boardH)
                    .background {
                        Image("backGround1")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    }
                    .overlay(
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                let cp1CPU = vm.passedCP1.indices.contains(1) && vm.passedCP1[1]
                                let cp2CPU = vm.passedCP2.indices.contains(1) && vm.passedCP2[1]

                                Image(systemName: cp1CPU ? "star.fill" : "star")
                                    .foregroundStyle(cp1CPU ? .yellow : .gray)
                                Image(systemName: cp2CPU ? "star.fill" : "star")
                                    .foregroundStyle(cp2CPU ? .yellow : .gray)
                            }
                            .font(.bestTenCaption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            Badge(player: vm.players[1],
                                  active: vm.turn == 1,
                                  tint: .red,
                                  total: vm.totalAssets(for: 1)
                            )
                        }
                        .padding(.bottom, 10)
                        .padding(.trailing, 12)
                        .allowsHitTesting(false),
                        alignment: .bottomTrailing
                    )
                    .overlay(
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                let cp1Player = vm.passedCP1.indices.contains(0) && vm.passedCP1[0]
                                let cp2Player = vm.passedCP2.indices.contains(0) && vm.passedCP2[0]

                                Image(systemName: cp1Player ? "star.fill" : "star")
                                    .foregroundStyle(cp1Player ? .yellow : .gray)
                                Image(systemName: cp2Player ? "star.fill" : "star")
                                    .foregroundStyle(cp2Player ? .yellow : .gray)
                            }
                            .font(.bestTenCaption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Badge(player: vm.players[0],
                                  active: vm.turn == 0,
                                  tint: .blue,
                                  total: vm.totalAssets(for: 0)
                            )
                        }
                        .padding(.bottom, 10)
                        .padding(.leading, 12)
                        .allowsHitTesting(false),
                        alignment: .bottomLeading
                    )
                    .overlay(alignment: .center) {
                        if let card = vm.presentingCard {
                            CardDetailOverlay(
                                card: card,
                                vm: vm,
                                onClose: { vm.closeCardPopup() }
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                            .transition(.opacity.combined(with: .scale))
                            .zIndex(900)
                        }
                    }
                    .overlay(alignment: .top) {
                        if vm.mustDiscardFor == 0 {
                            instructionBadge("捨てる手札を選択してください")
                        } else if vm.isSelectingSwapCreature {
                            instructionBadge("デジレプ選択")
                        } else if let text = selectionInstruction(for: vm.specialPending) {
                            instructionBadge(text)
                        }
                    }
                    
                    if vm.mustDiscardFor == 0 {
                        ZStack {
                            Color.black.opacity(0.7)
                                .ignoresSafeArea()
                            VStack {
                                Spacer()
                                Text("捨てる手札を選択")
                                    .foregroundColor(.white)
                                    .font(.bestTenHeadline)
                                Spacer()
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    
                    if vm.showCheckpointOverlay {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text(vm.checkpointMessage ?? "チェックポイント通過")
                                    .font(.bestTenHeadline)
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
                        .zIndex(999)
                    }
                    
                    if let drawCard = vm.drawPreviewCard {
                        DrawCardOverlay(
                            vm: vm,
                            card: drawCard,
                            onFinished: {
                                vm.confirmDrawPreview()
                            }
                        )
                        .transition(.opacity)
                        .zIndex(1300)
                    }

                    if let npcSpellCard = vm.npcSpellPreviewCard {
                        NPCSpellPreviewOverlay(vm: vm, card: npcSpellCard)
                            .transition(.opacity)
                            .zIndex(1250)
                    }
                    
                    if let idx = vm.inspectTarget,
                       let iv = vm.makeInspectView(for: idx, viewer: 0) {
                        CreatureInfoPanel(iv: iv, onClose: { vm.closeInspect() })
                            .padding(.top, 8)
                            .padding(.horizontal, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .zIndex(10)
                    }
                    
                    if let sheet = vm.activeSpecialSheet {
                        ZStack {
                            Color.black.opacity(0.35)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    vm.activeSpecialSheet = nil
                                }
                            Group {
                                switch sheet {
                                case .levelUp(let tile):
                                    PopupCard {
                                        LevelUpSheetView(vm: vm, tile: tile)
                                    }
                                case .buySpell:
                                    PopupCard {
                                        PurchaseSpellSheetView(vm: vm)
                                    }
                                }
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: vm.activeSpecialSheet)
                        .zIndex(80)
                    }
                    
                    if vm.sellConfirmTile != nil {
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                let before = vm.players[0].gold
                                let after  = vm.sellPreviewAfterGold

                                Text("売却しますか？").font(.bestTenHeadline)
                                Text("-\(max(0, -before)) GOLD → \(after) GOLD").font(.bestTenSubheadline)

                                HStack {
                                    Button("キャンセル") { vm.cancelSellTile() }
                                    Spacer().frame(width: 12)
                                    Button("OK") { vm.confirmSellTile() }.bold()
                                }
                                .padding(.top, 8)
                            }
                            .padding(16)
                            .frame(maxWidth: 300)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: vm.sellConfirmTile != nil)
                    }
                    
                    if let idx = vm.pendingSwapHandIndex,
                       vm.hands.indices.contains(0),
                        vm.hands[0].indices.contains(idx) {

                        let price = vm.hands[0][idx].stats?.cost ?? 0
                        let canSwap = vm.canSwapCreature(withHandIndex: idx)
                        ZStack {
                            Color.black.opacity(0.35).ignoresSafeArea()
                            VStack(spacing: 12) {
                                Text("交換しますか？")
                                    .font(.bestTenHeadline)
                                    .multilineTextAlignment(.center)
                                Text("必要コスト \(price) G")
                                    .font(.bestTenSubheadline)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Button(canSwap ? "交換" : "G不足") {
                                        guard canSwap else { return }
                                        vm.confirmSwapPending()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!canSwap)

                                    Button("キャンセル") {
                                        vm.cancelSwapPending()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
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
                        .zIndex(998)
                    }
                    
                    if vm.isTurnTransition {
                        TurnTransitionOverlay()
                            .transition(.opacity)
                    }
                    
                    if vm.showBattleOverlay, let L = vm.battleLeft, let R = vm.battleRight {
                        BattleOverlayView(
                            left: L,
                            right: R,
                            attribute: vm.battleAttr,
                            defenderHasFirstStrike: vm.defenderHasFirstStrike,
                            isItemSelecting: $vm.isBattleItemSelectionPhase,
                            isShowingBattleSpellEffect: vm.isShowingBattleSpellEffect,
                            battleSpellEffectID: vm.battleSpellEffectID
                        ) { finalL, finalR in
                            vm.finishBattle(finalL: finalL, finalR: finalR)
                        }
                        .zIndex(100)
                    }
                    
                    if let card = vm.presentingCard {
                        ZStack {
                            // 背景を少し暗くする（不要なら消してOK）
                            Color.black.opacity(0.45)
                                .ignoresSafeArea()
                                .onTapGesture { vm.closeCardPopup() }

                            CardDetailOverlay(
                                card: card,
                                vm: vm,
                                onClose: { vm.closeCardPopup() }
                            )
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                        }
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1200)
                    }
                    
                    // ★ 相手手札削除用：NPC 手札一覧表示オーバーレイ
                    if vm.isSelectingOpponentHandToDelete,
                       let target = vm.deletingTargetPlayer {

                        ZStack {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()

                            VStack(spacing: 16) {
                                Text("削除するカードを選択")
                                    .font(.bestTenHeadline)
                                    .padding(.top, 20)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(vm.hands[target].enumerated()), id: \.element.id) { idx, card in
                                            CardView(card: card)
                                                .onTapGesture {
                                                    // ここで「どのカードか」を GameVM に記録するだけ
                                                    vm.pendingDeleteHandIndex = idx
                                                    vm.deletePreviewCard = card
                                                }
                                        }
                                    }
                                    .padding()
                                }

                                Button("閉じる") {
                                    vm.isSelectingOpponentHandToDelete = false
                                    vm.pendingDeleteHandIndex = nil
                                    vm.deletingTargetPlayer = nil
                                    vm.deletePreviewCard = nil
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.systemBackground))
                            )
                            .padding()
                        }
                        .zIndex(1500)
                    }

                    // ★ 相手手札削除用：削除確認オーバーレイ
                    if let delCard = vm.deletePreviewCard,
                       vm.pendingDeleteHandIndex != nil,
                       vm.isSelectingOpponentHandToDelete {

                        ZStack {
                            Color.black.opacity(0.6)
                                .ignoresSafeArea()

                            VStack(spacing: 16) {
                                Text("削除しますか？")
                                    .font(.bestTenHeadline)

                                // 単純にカード絵だけ大きく見せる
                                CardView(card: delCard)
                                    .frame(width: 150)

                                HStack(spacing: 20) {
                                    Button("削除") {
                                        if let target = vm.deletingTargetPlayer,
                                           let idx = vm.pendingDeleteHandIndex,
                                           vm.hands[target].indices.contains(idx)
                                        {
                                            vm.hands[target].remove(at: idx)
                                            vm.battleResult = "カードを削除"
                                        }
                                        // 状態リセット
                                        vm.deletePreviewCard = nil
                                        vm.pendingDeleteHandIndex = nil
                                        vm.isSelectingOpponentHandToDelete = false
                                        vm.deletingTargetPlayer = nil
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("戻る") {
                                        // 一覧画面に戻るだけ（削除モードは継続）
                                        vm.deletePreviewCard = nil
                                        vm.pendingDeleteHandIndex = nil
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                            )
                            .padding()
                        }
                        .zIndex(2000)
                    }

                    // ★ NPC による削除結果表示（プレイヤー手札が消されたとき）
                    if let delCard = vm.deletePreviewCard,
                       !vm.isSelectingOpponentHandToDelete,
                       vm.deletingTargetPlayer == 0 {   // 消されたのがプレイヤー側

                        ZStack {
                            Color.black.opacity(0.5)
                                .ignoresSafeArea()

                            VStack(spacing: 16) {
                                Text("このカードが削除されました")
                                    .font(.bestTenHeadline)

                                CardView(card: delCard)
                                    .frame(width: 150)

                                Button("OK") {
                                    vm.deletePreviewCard = nil
                                    vm.deletingTargetPlayer = nil
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.8))
                            )
                            .padding()
                        }
                        .zIndex(2000)
                    }
                    
                    if let tile = vm.pendingFullHealTile,
                       vm.hp.indices.contains(tile),
                       vm.hpMax.indices.contains(tile) {

                        let currentHP = vm.hp[tile]
                        let maxHP = vm.hpMax[tile]

                        ZStack {
                            Color.black.opacity(0.6)
                                .ignoresSafeArea()

                            VStack(spacing: 16) {
                                Text("回復しますか？")
                                    .font(.bestTenHeadline)

                                Text("現在の体力: \(currentHP)/\(maxHP)")
                                    .font(.bestTenSubheadline)

                                HStack(spacing: 20) {
                                    Button("OK") {
                                        vm.confirmFullHeal()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("閉じる") {
                                        vm.cancelFullHealConfirm()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: 300)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                        }
                        .transition(.opacity)
                    }

                    if vm.isSelectingDamageTarget,
                       let tile = vm.pendingDamageTile,
                       vm.damageCandidateTiles.contains(tile),
                       vm.pendingDamageAmount > 0 {

                        ZStack {
                            Color.black.opacity(0.55)
                                .ignoresSafeArea()

                            VStack(spacing: 14) {
                                Text(vm.pendingDamageSpellName ?? "スペル")
                                    .font(.bestTenHeadline)
                                    .padding(.top, 4)

                                Text("このデジレプに \(vm.pendingDamageAmount) 使用しますか？")
                                    .multilineTextAlignment(.center)
                                    .font(.bestTenSubheadline)

                                Button("使用する") {
                                    vm.confirmDamageSpell()
                                }
                                .buttonStyle(.borderedProminent)

                                HStack(spacing: 12) {
                                    Button("対象変更") {
                                        vm.cancelDamageConfirm()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("選択終了") {
                                        vm.cancelDamageSelection()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                            )
                            .shadow(radius: 12)
                        }
                        .transition(.opacity)
                        .zIndex(110)
                    }

                    if vm.isSelectingTileAttributeTarget,
                       let tile = vm.pendingTileAttributeTarget,
                       vm.tileAttributeCandidateTiles.contains(tile),
                       let kind = vm.pendingTileAttributeKind {

                        ZStack {
                            Color.black.opacity(0.55)
                                .ignoresSafeArea()

                            VStack(spacing: 14) {
                                Text(vm.pendingTileAttributeSpellName ?? "スペル")
                                    .font(.bestTenHeadline)
                                    .padding(.top, 4)

                                Text("土地を\(vm.tileAttributeName(for: kind)) に改変しますか？")
                                    .multilineTextAlignment(.center)
                                    .font(.bestTenSubheadline)

                                Button("土地改変") {
                                    vm.confirmTileAttributeChange()
                                }
                                .buttonStyle(.borderedProminent)

                                HStack(spacing: 12) {
                                    Button("対象変更") {
                                        vm.cancelTileAttributeConfirm()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("選択終了") {
                                        vm.cancelTileAttributeSelection()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                            )
                            .shadow(radius: 12)
                        }
                        .transition(.opacity)
                        .zIndex(110)
                    }

                    if vm.isSelectingPoisonTarget,
                       let tile = vm.pendingPoisonTile,
                       vm.poisonCandidateTiles.contains(tile) {

                        ZStack {
                            Color.black.opacity(0.55)
                                .ignoresSafeArea()

                            VStack(spacing: 14) {
                                Text(vm.pendingPoisonSpellName ?? "スペル")
                                    .font(.bestTenHeadline)
                                    .padding(.top, 4)

                                Text("デジレプを毒状態にしますか？")
                                    .multilineTextAlignment(.center)
                                    .font(.bestTenSubheadline)

                                Button("毒を付与") {
                                    vm.confirmPoisonSpell()
                                }
                                .buttonStyle(.borderedProminent)

                                HStack(spacing: 12) {
                                    Button("対象変更") {
                                        vm.cancelPoisonConfirm()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("選択終了") {
                                        vm.cancelPoisonSelection()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                            )
                            .shadow(radius: 12)
                        }
                        .transition(.opacity)
                        .zIndex(111)
                    }

                    if vm.isSelectingCleanseTarget,
                       let tile = vm.pendingCleanseTile,
                       vm.cleanseCandidateTiles.contains(tile) {

                        ZStack {
                            Color.black.opacity(0.55)
                                .ignoresSafeArea()

                            VStack(spacing: 14) {
                                Text(vm.pendingCleanseSpellName ?? "スペル")
                                    .font(.bestTenHeadline)
                                    .padding(.top, 4)

                                Text("効果を解除しますか？")
                                    .multilineTextAlignment(.center)
                                    .font(.bestTenSubheadline)

                                Button("効果解除") {
                                    vm.confirmCleanseSpell()
                                }
                                .buttonStyle(.borderedProminent)

                                HStack(spacing: 12) {
                                    Button("対象変更") {
                                        vm.cancelCleanseConfirm()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("選択終了") {
                                        vm.cancelCleanseSelection()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.systemBackground))
                            )
                            .shadow(radius: 12)
                        }
                        .transition(.opacity)
                        .zIndex(112)
                    }
                    
                    // sp-decay 用：レベルダウン確認ウインドウ
                    if let tile = vm.pendingLandLevelChangeTile,
                       vm.level.indices.contains(tile) {

                        let currentLevel = vm.level[tile]

                        ZStack {
                            Color.black.opacity(0.6)
                                .ignoresSafeArea()

                            VStack(spacing: 16) {
                                Text("レベルを１下げますか？")
                                    .font(.bestTenHeadline)

                                Text("現在のレベル: Lv\(currentLevel)")
                                    .font(.bestTenSubheadline)

                                HStack(spacing: 20) {
                                    Button("OK") {
                                        vm.confirmLandLevelChange()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("閉じる") {
                                        vm.cancelLandLevelChangeConfirm()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: 300)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                        }
                        .transition(.opacity)
                    }
                    
                    // ★ sp-devastation の確認ダイアログ
                    if let tile = vm.pendingLandTollZeroTile,
                       vm.toll.indices.contains(tile)
                    {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            Text("通行量を 0 にしますか？")
                                .font(.bestTenHeadline)
                                .multilineTextAlignment(.center)

                            Text("現在の通行量: \(vm.toll[tile])G")
                                .font(.bestTenSubheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Button("OK") {
                                    vm.confirmLandTollZero()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("閉じる") {
                                    vm.cancelLandTollZeroConfirm()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .frame(maxWidth: 260)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                        .zIndex(101)
                    }
                    
                    // ★ sp-harvest の確認ダイアログ
                    if let tile = vm.pendingLandTollDoubleTile,
                       vm.toll.indices.contains(tile)
                    {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            Text("通行量を 2 倍にしますか？")
                                .font(.bestTenHeadline)
                                .multilineTextAlignment(.center)

                            Text("現在の通行量: \(vm.toll[tile])G")
                                .font(.bestTenSubheadline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                Button("OK") {
                                    vm.confirmLandTollDouble()
                                }
                                .buttonStyle(.borderedProminent)

                                Button("閉じる") {
                                    vm.cancelLandTollDoubleConfirm()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .frame(maxWidth: 260)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                    
                    if vm.isShowingDiceGlitch, let n = vm.diceGlitchNumber {
                        GeometryReader { diceGeo in
                            let minEdge = min(diceGeo.size.width, diceGeo.size.height)
                            let largeSize = min(minEdge * 0.45, 240)
                            let compactSize = max(72, minEdge * 0.18)
                            let cornerPadding: CGFloat = 20
                            let safeTop = diceGeo.safeAreaInsets.top
                            let victoryBarHeight: CGFloat = 52
                            let pinnedPoint = CGPoint(
                                x: cornerPadding + compactSize / 2,
                                y: safeTop + victoryBarHeight + cornerPadding + compactSize / 2
                            )
                            let centerPoint = CGPoint(x: diceGeo.size.width / 2,
                                                      y: diceGeo.size.height / 2)

                            DiceGlitchView(
                                number: n,
                                duration: 0.35,
                                mode: vm.diceGlitchPinned ? .pinned : .rolling,
                                onFinished: {
                                    vm.handleDiceGlitchRevealFinished()
                                }
                            )
                            .frame(width: vm.diceGlitchPinned ? compactSize : largeSize,
                                   height: vm.diceGlitchPinned ? compactSize : largeSize)
                            .position(vm.diceGlitchPinned ? pinnedPoint : centerPoint)
                            .animation(.easeInOut(duration: 0.35), value: vm.diceGlitchPinned)
                        }
                        .allowsHitTesting(false)
                        .zIndex(30)
                    }

                    if let effect = vm.activeBoardWideEffect {
                        BoardWideSpellEffectView(kind: effect)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                            .zIndex(5)
                    }

                }

// -------------------------------------------------------------------------------
//　　　　　　　　　　　　　　　　　　　下部：操作エリア（自プレイヤー専用）
// -------------------------------------------------------------------------------

                ZStack(alignment: .center) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Spacer()
                                Button("🎲 Roll") { vm.rollDice() }
                                    .disabled(!(vm.turn == 0 && vm.phase == .ready && vm.mustDiscardFor == nil))
                                
                                Button("✅ End") { vm.endTurn() }
                                    .disabled(!(vm.turn == 0 && vm.phase == .moved))
                                    .disabled(!vm.canEndTurn)
                                
                                Spacer()
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        Divider().frame(height: controlsH * 0.8)

                        OverlappingHandView(cards: vm.hands[0],
                                            focusedIndex: $vm.focusedHandIndex,
                                            dragOffset: $vm.handDragOffset,
                                            onTap: { index in
                            let card = vm.hands[0][index]
                            if vm.isSelectingSwapCreature,
                               card.kind == .creature {
                                vm.selectSwapHandIndex(index)
                            } else {
                                vm.openCard(card)
                            }
                        }, onTapUp: { index in
                            let card = vm.hands[0][index]
                            vm.openCard(card)
                        },
                        highlightCreatureCards: vm.highlightSummonableCreatures)
                        .frame(height: controlsH * 0.9)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    if let card = vm.presentingCard,
                       card.kind == .creature,
                       vm.turn == 0,
                       vm.mustDiscardFor == nil {

                        let t = vm.players[0].pos
                        let isMy = vm.owner.indices.contains(t) && vm.owner[t] == 0
                        let isCPU = vm.owner.indices.contains(t) && vm.owner[t] == 1
                        let hasCreature = vm.creatureSymbol.indices.contains(t) && vm.creatureSymbol[t] != nil
                        let canPlace = (vm.owner.indices.contains(t) && vm.owner[t] == nil) && vm.canPlaceCreature(at: t)

                        // 1) 空き地（未占領） → 配置するか？
                        if canPlace {
                            ZStack {
                                VStack {
                                    Text("このデジレプを配置しますか？")
                                        .font(.bestTenSubheadline).bold()
                                    
                                    HStack(spacing: 12) {
                                        let price = card.stats?.cost ?? 0
                                        let enoughGold = vm.players[0].gold >= price

                                        Button(enoughGold ? "配置" : "G不足") {
                                            guard enoughGold else { return }
                                            vm.confirmPlaceCreatureFromHand(card, at: t, by: 0)
                                            vm.closeCardPopup()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .disabled(!enoughGold)
                                        
                                        Button("キャンセル") {
                                            vm.closeCardPopup()
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .background {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        // 2) 自分のデジレプが設置済み
                        else if isMy && hasCreature {
                            if vm.phase == .ready {
                                ZStack {
                                    VStack(spacing: 12) {
                                        Text("占領済みです")
                                            .font(.bestTenSubheadline).bold()
                                        Button("キャンセル") {
                                            vm.closeCardPopup()
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                }
                                .frame(maxWidth: .infinity)
                                .background {
                                    Image("underMenuBackgroundRed")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                                .clipped()
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        // 3) CPUのデジレプが設置済み
                        else if isCPU && hasCreature {
                            ZStack {
                                VStack(spacing: 12) {
                                    Text("相手の領地です")
                                        .font(.bestTenSubheadline).bold()
                                    Button("キャンセル") {
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            .frame(maxWidth: .infinity)
                            .background {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        else {
                            ZStack {
                                VStack(spacing: 12) {
                                    Text("この場所では配置できません")
                                        .font(.bestTenSubheadline).bold()
                                    Button("キャンセル") {
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                            .frame(maxWidth: .infinity)
                            .background {
                                Image("underMenuBackgroundRed")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    
                    if (vm.landedOnOpponentTileIndex != nil),
                       vm.turn == 0, vm.phase == .moved, !vm.expectBattleCardSelection {
                        let canBattle = vm.hasSummonableCreature(for: 0)
                        ZStack{
                            VStack(spacing: 12) {
                                Text("相手の領地です").bold()

                                if canBattle {
                                    HStack(spacing: 12) {
                                        Button("戦闘する") { vm.chooseBattle() }
                                            .buttonStyle(.borderedProminent)
                                        Button("通行料を払う") { vm.payTollAndEndChoice() }
                                            .buttonStyle(.borderedProminent)
                                    }
                                    .padding(8)
                                } else {
                                    VStack(spacing: 8) {
                                        Text("召喚できるデジレプがいないため戦闘できません")
                                            .font(.bestTenFootnote)
                                        Button("通行料を払う") { vm.payTollAndEndChoice() }
                                            .buttonStyle(.borderedProminent)
                                    }
                                    .padding(8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    
                    if vm.showSpecialMenu {
                        ZStack{
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
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }

                    if let text = vm.battleResult {
                        ZStack {
                            VStack(spacing: 12) {
                                Text(text)
                                    .multilineTextAlignment(.center)
                                    .font(.bestTenTitle3).bold()
                                    .padding(.vertical, 4)

                                Button("閉じる") {
                                    vm.battleResult = nil
                                    vm.cancelFullHealSelection()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(radius: 10)
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    
                    // ★★★ 自軍マスに止まったとき用の CreatureMenuView 表示 ★★★
                    if vm.showCreatureMenu,
                       let t = vm.creatureMenuTile,
                       vm.turn == 0 {

                        ZStack {
                            CreatureMenuView(
                                vm: vm,
                                tile: t,
                                onChangeCreature: {
                                    // 交換モード開始
                                    vm.startCreatureSwap(from: t)
                                },
                                onClose: {
                                    vm.showCreatureMenu = false
                                    vm.creatureMenuTile = nil
                                }
                            )
                            .frame(height: controlsH)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    
                    if let card = vm.presentingCard,
                       card.kind == .spell,
                       vm.turn == 0,
                       vm.mustDiscardFor == nil,
                       isTargetedDiceSpell(card),
                       vm.shopSpellForDetail == nil {
                        ZStack {
                            VStack {
                                Text("スペル使用先を選択")
                                    .font(.bestTenSubheadline).bold()

                                HStack(spacing: 12) {
                                    Button("自分") {
                                        vm.useTargetedDiceSpell(card, target: 0)
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("NPC") {
                                        vm.useTargetedDiceSpell(card, target: 1)
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("キャンセル") {
                                        vm.closeCardPopup()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if vm.isForcedSaleMode && vm.turn == 0 {
                        ZStack {
                            Text("通行料が支払えません\n売却地を選択（現在:- \(vm.debtAmount) G）")
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            Image("underMenuBackgroundRed")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    
                    VStack {
                        Image("line")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                        Spacer()
                    }
                }
                .frame(height: controlsH)
                .frame(maxWidth: .infinity)
                .background {
                    let backgroundName = vm.currentSpecialKind != nil ? "underMenuBackgroundRed" : "underMenuBackground"
                    Image(backgroundName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .overlay(Divider(), alignment: .top)
            }
            if vm.showVictoryBanner, let status = vm.victoryStatus {
                VictoryBannerView(text: status.displayText)
                    .transition(.opacity)
                    .zIndex(2000)
            }
            }
            .opacity(isFadingOut ? 0 : 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .top) {
                VictoryConditionBar()
            }
        }
        .onChange(of: vm.shouldReturnToDeckBuilder) { oldValue, newValue in
            guard newValue else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                isFadingOut = true
            }
            SoundManager.shared.stopBGM()
            let completion = {
                if let onBattleEnded {
                    onBattleEnded()
                } else {
                    dismiss()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                completion()
            }
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            if vm.showEndTurnWithoutSummonConfirm {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("クリーチャーを設置せずに終了しますか？")
                            .font(.bestTenHeadline)
                            .multilineTextAlignment(.center)
                        Text("空き地に配置しないと領地にできません。")
                            .font(.bestTenFootnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Button("キャンセル") {
                                vm.cancelEndTurnWithoutSummonWarning()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("終了する") {
                                vm.confirmEndTurnWithoutSummon()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 20)
                    .padding()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            SoundManager.shared.playBGM(.map)
        }
        // ターンチェンジ状態の変化に応じて BGM 切り替え
        .onChange(of: vm.isTurnTransition) { oldValue, newValue in
            if newValue {
                // ターンチェンジ開始 → ターンBGM
                SoundManager.shared.playBGM(.turn)
            } else {
                // ターンチェンジ終了
                if vm.showBattleOverlay {
                    // もしこの時すでにバトルに入っていたらバトルBGM
                    SoundManager.shared.playBGM(.battle)
                } else {
                    // 通常マップ状態に戻る
                    SoundManager.shared.playBGM(.map)
                }
            }
        }
        // バトルオーバーレイ表示状態の変化に応じて BGM 切り替え
        .onChange(of: vm.showBattleOverlay) { oldValue, newValue in
            if newValue {
                // バトル開始
                SoundManager.shared.playBGM(.battle)
            } else {
                // バトル終了
                if vm.isTurnTransition {
                    // まだターンチェンジ演出中ならターンBGMを維持
                    SoundManager.shared.playBGM(.turn)
                } else {
                    // それ以外は通常マップBGMへ
                    SoundManager.shared.playBGM(.map)
                }
            }
        }
    }
    
    private func isTargetedDiceSpell(_ card: Card) -> Bool {
        guard card.kind == .spell, let e = card.spell else { return false }
        switch e {
        case .fixNextRoll(let n):
            return (1...6).contains(n)
        case .doubleDice:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func instructionBadge(_ text: String) -> some View {
        Text(text)
            .font(.bestTenHeadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 8)
    }

    private func selectionInstruction(for pending: GameVM.SpecialPendingAction?) -> String? {
        guard let pending else { return nil }
        switch pending {
        case .pickMoveSource:
            return "移動するデジレプを選択（50G）"
        case .pickMoveDestination:
            return "移動先を選択（50G）"
        case .pickLevelUpSource:
            return "強化する領地を選択"
        }
    }
}

private struct VictoryConditionBar: View {

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                Text("勝利条件：TOTL 5,000G")
                    .font(.bestTenSubheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.75))
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
}

private struct VictoryBannerView: View {
    let text: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            Text(text)
                .font(.bestTen(size: 48))
                .fontWeight(.heavy)
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.6), radius: 12)
        }
        .allowsHitTesting(false)
    }
}


private extension GameVM.VictoryStatus {
    var displayText: String {
        switch self {
        case .win:  return "YOU WIN"
        case .lose: return "YOU LOSE"
        }
    }
}

struct CardDetailOverlay: View {
    let card: Card
    @ObservedObject var vm: GameVM
    let onClose: () -> Void
    
    @State private var appearOpacity: Double = 0
    @State private var appearOffsetY: CGFloat = 50
    @State private var spinAngle: Double = 0
    @State private var isDiscardingCard = false
    @State private var discardCompletionHandled = false

    private let frameImageName = "cardL"
    private let backImageName  = "cardLreverse"
    private var primaryAction: (title: String, action: (() -> Void)?, enabled: Bool) {

        // コスト取得ヘルパー
        func spellCostForUI(_ card: Card) -> Int {
            // スペルは CardDatabase の定義からコストを取得
            CardDatabase.definition(for: card.id)?.cost ?? 0
        }

        func creatureCostForUI(_ card: Card) -> Int {
            // クリーチャーは stats.cost を使用
            card.stats?.cost ?? 0
        }

        let gold: Int
        if vm.isBattleItemSelectionPhase {
            // バトルアイテムを操作するのは常にプレイヤー（ID 0）
            gold = vm.players[0].gold
        } else {
            // 通常時はターンプレイヤーのGOLD
            gold = vm.players[vm.turn].gold
        }
        
        // ① バトル中の装備アイテム使用
        if vm.isBattleItemSelectionPhase {
            let cost = card.stats?.cost ?? spellCostForUI(card)
            let hasEnoughGold = gold >= cost
            let title = hasEnoughGold ? "装備使用" : "G不足"

            return (
                title,
                (hasEnoughGold)
                    ? {
                        // ★ コスト支払い＋効果適用＋手札削除は
                        //   GameVM.finishBattleItemSelection に集約
                        vm.finishBattleItemSelection(card, for: 0)
                        onClose()
                      }
                    : nil,
                hasEnoughGold
            )
        }

        // ② 手札捨て（コスト関係なし）
        if vm.mustDiscardFor == 0 {
            let title = isDiscardingCard ? "削除中..." : "捨てる"
            return (
                title,
                isDiscardingCard ? nil : { startDiscardSequence() },
                !isDiscardingCard
            )
        }

        // ③ スペル使用（事前スペル：ロール前）
        if vm.phase == .ready && card.kind == .spell {
            if vm.isBattleOnlySpell(card) && !vm.isBattleItemSelectionPhase {
                return ("戦闘時のみ", nil, false)
            }

            let cost = spellCostForUI(card)
            let hasEnoughGold = gold >= cost
            let title = hasEnoughGold ? "スペル使用" : "G不足"

            return (
                title,
                (vm.turn == 0 && hasEnoughGold)
                    ? { vm.useSpellPreRoll(card); onClose() }
                    : nil,
                vm.turn == 0 && hasEnoughGold
            )
        }

        // ④ 移動後のカード使用
        if vm.turn == 0 && vm.phase == .moved {

            // 「戦闘する」：クリーチャーカードをバトル用に選択
            if vm.expectBattleCardSelection && card.kind == .creature {
                let cost = creatureCostForUI(card)
                let hasEnoughGold = gold >= cost
                let title = hasEnoughGold ? "戦闘する" : "G不足"

                return (
                    title,
                    hasEnoughGold
                        ? { vm.startBattle(with: card); onClose() }
                        : nil,
                    hasEnoughGold
                )
            } else {
                // 通常のカード使用（クリーチャー／スペル共通）
                let cost: Int
                switch card.kind {
                case .spell:
                    if vm.isBattleOnlySpell(card) && !vm.isBattleItemSelectionPhase {
                        return ("戦闘時のみ", nil, false)
                    }
                    cost = spellCostForUI(card)
                case .creature:
                    cost = creatureCostForUI(card)
                }

                let hasEnoughGold = gold >= cost
                let title = hasEnoughGold ? "カード使用" : "G不足"

                return (
                    title,
                    hasEnoughGold
                        ? { vm.useCardAfterMove(card); onClose() }
                        : nil,
                    hasEnoughGold
                )
            }
        }

        // デフォルト：何もできない
        return ("使用できません", nil, false)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(card.name)
                .font(.bestTen(size: 26))
                .fontWeight(.semibold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundColor(.white)
                .frame(maxWidth: 430)
                .padding(.horizontal, 20)

            // 角度制御版
            flipCardAngle
                .frame(maxWidth: 430)
                .opacity(appearOpacity)
                .onAppear {
                    appearOpacity = 0
                    withAnimation(.easeOut(duration: 0.7)) { appearOpacity = 1 }

                    spinAngle = 0
                    withAnimation(.linear(duration: 0.6)) {
                        spinAngle = 360
                    }
                }
                .onDisappear {
                    appearOpacity = 0
                    spinAngle = 0
                }

            if let shopSpell = vm.shopSpellForDetail {
                // ★ スペルショップから開いたとき
                let canBuy = vm.players[vm.turn].gold >= shopSpell.price

                HStack(spacing: 10) {
                    Button(canBuy ? "購入" : "G不足") {
                        guard canBuy else { return }
                        vm.confirmPurchaseSpell(shopSpell)   // GOLD 消費 + 手札に追加 + シート閉じ
                        vm.shopSpellForDetail = nil         // コンテキストクリア
                        onClose()                           // カード詳細を閉じる（presentingCard=nil）
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canBuy)

                    Button("閉じる") {
                        vm.shopSpellForDetail = nil
                        onClose()
                    }
                    .buttonStyle(.borderedProminent)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(radius: 12)
                    )
                }

            } else {
                // ★ 従来どおりの通常モード
                HStack(spacing: 10) {
                    Button(primaryAction.title) { primaryAction.action?() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!primaryAction.enabled)
                    Button("閉じる") { onClose() }
                        .buttonStyle(.borderedProminent)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(radius: 12)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
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
            isDiscardingCard = false
            discardCompletionHandled = false
        }
        .onDisappear {
            appearOpacity = 0
            appearOffsetY = 50
            spinAngle = 0
            isDiscardingCard = false
            discardCompletionHandled = false
        }
    }

    private var flipCardAngle: some View {
        FlipAngle(angle: spinAngle) {
            FrontCardFace(
                card: card,
                vm: vm,
                frameImageName: frameImageName,
                isDissolving: $isDiscardingCard,
                onDissolveCompleted: completeDiscardIfNeeded
            )
        } back: {
            BackCardFace(frameImageName: backImageName)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.linear(duration: 0.75)) {
                spinAngle += 360
            }
        }
    }

    private func startDiscardSequence() {
        guard !isDiscardingCard else { return }
        isDiscardingCard = true
        SoundManager.shared.playDeleteSound()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            completeDiscardIfNeeded()
        }
    }

    private func completeDiscardIfNeeded() {
        guard isDiscardingCard else { return }
        guard !discardCompletionHandled else { return }
        discardCompletionHandled = true
        if vm.mustDiscardFor == 0 {
            vm.discard(card, for: 0)
        }
        onClose()
    }
}

struct NPCSpellPreviewOverlay: View {
    @ObservedObject var vm: GameVM
    let card: Card

    @State private var offsetY: CGFloat = -40
    @State private var opacity: Double = 0
    @State private var spinAngle: Double = 0

    private let frameImageName = "cardL"
    private let backImageName  = "cardLreverse"

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("NPCがスペルを使用")
                    .font(.bestTenHeadline)
                    .foregroundColor(.white)

                FlipAngle(angle: spinAngle) {
                    FrontCardFace(card: card, vm: vm, frameImageName: frameImageName)
                } back: {
                    BackCardFace(frameImageName: backImageName)
                }
                .frame(maxWidth: 430)
                .onTapGesture {
                    withAnimation(.linear(duration: 0.75)) {
                        spinAngle += 360
                    }
                }
            }
            .padding(20)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                offsetY = -40
                opacity = 0
                spinAngle = 0
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    offsetY = 0
                    opacity = 1
                }
                withAnimation(.linear(duration: 0.6)) {
                    spinAngle = 360
                }
            }
        }
    }
}

struct DrawCardOverlay: View {
    @ObservedObject var vm: GameVM
    let card: Card
    let onFinished: () -> Void

    @State private var offsetY: CGFloat = -40
    @State private var opacity: Double = 0
    @State private var spinAngle: Double = 0

    private let frameImageName = "cardL"
    private let backImageName  = "cardLreverse"

    var body: some View {
        ZStack {
            // 背景を暗くして他の操作を封じる
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(" ")
                    .font(.bestTenHeadline)
                    .foregroundColor(.white)

                // 既存の Flip 表現を再利用
                FlipAngle(angle: spinAngle) {
                    FrontCardFace(card: card, vm: vm, frameImageName: frameImageName)
                } back: {
                    BackCardFace(frameImageName: backImageName)
                }
                .frame(maxWidth: 430)
                .onTapGesture {
                    // カードタップでクルッと回転だけさせる
                    withAnimation(.linear(duration: 0.75)) {
                        spinAngle += 360
                    }
                }

                Button("OK") {
                    dismissWithFlyToHand()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
            .offset(y: offsetY)
            .opacity(opacity)
            .onAppear {
                // ふわっと上から出てくる
                offsetY = -40
                opacity = 0
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                    offsetY = 0
                    opacity = 1
                }
                // 最初に一回転
                spinAngle = 0
                withAnimation(.linear(duration: 0.6)) {
                    spinAngle = 360
                }
            }
        }
    }

    private func dismissWithFlyToHand() {
        // 下方向へ移動しながらフェードアウト
        withAnimation(.easeInOut(duration: 0.6)) {
            offsetY = 300   // 画面下部方向へ
            opacity = 0
        }

        // アニメーション終了後に手札へ追加＆オーバーレイ終了
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onFinished()
        }
    }
}

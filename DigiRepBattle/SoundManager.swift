//
//  SoundManager.swift
//  DigiRepBattle
//
//  Created by 瀧村優也 on 2025/11/30.
//

import SwiftUI
import AVFoundation

enum BGMKind {
    case deck
    case map
    case turn   // ← map に被せる一時BGMとして扱う
    case battle
}

/// 効果音＋BGM 全体を管理するクラス
/// - map / deck / battle → 1つだけ再生（bgmPlayer）
/// - turnSound → mapSound とだけミックス可（別プレイヤーで再生＆フェード制御）
final class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()
    
    // 効果音(SE) 用プレイヤーたち
    private var players: [String: AVAudioPlayer] = [:]
    private var fadeTimers: [String: Timer] = [:]

    // メインBGM用プレイヤー（deck / map / battle）
    private var bgmPlayer: AVAudioPlayer?
    private(set) var currentBGM: BGMKind?

    // ターン演出用BGMプレイヤー（turnSound）
    private var turnPlayer: AVAudioPlayer?

    // mapSound の音量フェード用タイマー
    private var mapFadeTimer: Timer?

    // サウンドON/OFF
    var isSoundOn: Bool = true
    private let winSoundFadeDelay: TimeInterval = 4.0

    // MARK: - 効果音

    func playEffect(for kind: SpellEffectScene.EffectKind) {
        guard isSoundOn else { return }

        let fileName: String
        switch kind {
        case .heal:   fileName = "healSound"
        case .damage: fileName = "hitSound"
        case .buff:   fileName = "buffSound"
        case .debuff: fileName = "debuffSound"
        case .poison: fileName = "poisonSound"
        case .decay:  fileName = "decaySound"
        case .devastation: fileName = "devastationSound"
        case .place: fileName = "setSound"
        case .harvest: fileName = "harvestSound"
        case .tileSnow, .tileDesert, .tileVolcano, .tileJungle, .tilePlain:
            fileName = "tileChangeSound"
        }

        playSE(named: fileName)
    }

    func playBoardWideEffectSound(_ effect: BoardWideSpellEffectKind) {
        guard isSoundOn else { return }

        let name: String
        switch effect {
        case .storm:
            name = "stormSound"
        case .disaster:
            name = "disasterSound"
        case .cure:
            name = "cureSound"
        case .treasure:
            name = "coinSound"
        case .clairvoyance:
            name = "clairvoyanceSound"
        case .blizzard:
            name = "blizzardSound"
        case .eruption:
            name = "eruptionSound"
        case .heavyRain:
            name = "heavyRainSound"
        case .drought:
            name = "droughtSound"
        }

        playSE(named: name)
    }

    func playAttackSound() {
        playSE(named: "attackSound")
    }
    
    func playAttackSound2() {
        playSE(named: "attackSound2")
    }

    func playBattleSpellSound() {
        playSE(named: "battleSpellSound")
    }

    func playMoveSound() {
        playSE(named: "moveSound")
    }

    func playHandViewSound() {
        playSE(named: "handViewSound")
    }
    
    func playDeleteSound() {
        playSE(named: "deleteSound")
    }

    func playCheckpointSound() {
        playSE(named: "checkPointSound")
    }

    func playHomeSound() {
        playSE(named: "homeSound")
    }
    
    func playLevelSound() {
        playSE(named: "levelSound")
    }
    
    func playCriticalSound() {
        playSE(named: "criticalSound")
    }
    
    func playDeleteBugSound() {
        playSE(named: "deleteBug")
    }

    func playDoubleSound() {
        playSE(named: "double")
    }

    func playBuySound() {
        playSE(named: "buySound")
    }
    
    func playSellTileSound() {
        playSE(named: "sellTile")
    }
    
    func playStartSound() {
        playSE(named: "startSound")
    }

    func playWinSoundWithFade() {
        playSoundWithFadeOut(named: "winSound", delay: winSoundFadeDelay)
    }

    func playLoseSoundWithFade() {
        playSoundWithFadeOut(named: "loseSound")
    }

    private func playSE(named name: String) {
        guard isSoundOn else { return }
        guard let player = player(for: name) else { return }
        player.currentTime = 0
        player.volume = 1.0
        player.play()
    }

    private func player(for name: String) -> AVAudioPlayer? {
        if let player = players[name] {
            player.prepareToPlay()
            return player
        }

        let url: URL?
        // try Sounds/ subfolder first, then root for backward compatibility
        if let sub = Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds") {
            url = sub
        } else {
            url = Bundle.main.url(forResource: name, withExtension: "mp3")
        }

        guard let soundURL = url else {
            print("SE not found: \(name)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.numberOfLoops = 0
            player.prepareToPlay()
            players[name] = player
            return player
        } catch {
            print("Failed to play SE: \(error)")
            return nil
        }
    }

    private func playSoundWithFadeOut(named name: String,
                                      duration: TimeInterval = 3.0,
                                      delay: TimeInterval = 0.0) {
        guard isSoundOn else { return }
        guard let player = player(for: name) else { return }
        player.currentTime = 0
        player.volume = 1.0
        player.play()

        fadeTimers[name]?.invalidate()

        let startFade = { [weak self, weak player] in
            guard let self = self else { return }
            let steps = max(1, Int(duration / 0.15))
            var currentStep = 0
            let interval = duration / Double(steps)
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self, weak player] timer in
                guard let player = player else {
                    timer.invalidate()
                    return
                }
                currentStep += 1
                let progress = min(1.0, Double(currentStep) / Double(steps))
                player.volume = Float(max(0.0, 1.0 - progress))
                if currentStep >= steps {
                    player.stop()
                    timer.invalidate()
                    self?.fadeTimers[name] = nil
                }
            }
            self.fadeTimers[name] = timer
            RunLoop.main.add(timer, forMode: .common)
        }

        if delay <= 0 {
            startFade()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                startFade()
            }
        }
    }

    /// BGM 再生
    /// - .turn のときだけ mapSound に被せて再生＋フェード
    func playBGM(_ kind: BGMKind) {
        guard isSoundOn else { return }

        // ターンBGMだけは特別扱い：mapSound に被せる
        if kind == .turn {
            playTurnBGMWithMapFade()
            return
        }

        // deck / map / battle は「メインBGM」として扱う

        // すでに同じBGMを再生中なら何もしない
        if currentBGM == kind, bgmPlayer?.isPlaying == true {
            return
        }

        // モード切替時は turnBGM を止めて map の音量もリセット
        stopTurnBGM()

        // 既存のメインBGMを止める（deck/map/battle のいずれか）
        stopBGM()

        let fileName: String
        let shouldLoop: Bool

        switch kind {
        case .deck:
            fileName = "deckSound"
            shouldLoop = true
        case .map:
            fileName = "mapSound"
            shouldLoop = true
        case .battle:
            fileName = "battleSound"
            shouldLoop = true
        case .turn:
            // 上で return 済なのでここには来ない
            return
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("BGM not found: \(fileName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = shouldLoop ? -1 : 0
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            bgmPlayer = player
            currentBGM = kind
        } catch {
            print("Failed to play BGM: \(error)")
        }
    }

    /// メインBGM（deck / map / battle）を完全停止
    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        currentBGM = nil
    }

    /// turnSound を再生しつつ、mapSound をフェードアウト → 終了後フェードイン
    private func playTurnBGMWithMapFade() {
        guard isSoundOn else { return }

        // mapSound が再生中ならフェードダウン
        if currentBGM == .map, bgmPlayer != nil {
            fadeMapVolume(to: 0.2, duration: 0.5)   // 0.5秒で 20% まで下げる
        }

        // すでに turnSound をロード済みなら頭出しだけ
        if let player = turnPlayer {
            player.currentTime = 0
            player.play()
            return
        }

        guard let url = Bundle.main.url(forResource: "turnSound", withExtension: "mp3") else {
            print("BGM not found: turnSound")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = 0
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            turnPlayer = player
        } catch {
            print("Failed to play turn BGM: \(error)")
        }
    }

    /// turnSound を停止し、mapSound の音量・フェードをリセット
    private func stopTurnBGM() {
        mapFadeTimer?.invalidate()
        mapFadeTimer = nil

        turnPlayer?.stop()
        turnPlayer = nil

        // mapSound がメインのときは音量を戻しておく
        if currentBGM == .map {
            bgmPlayer?.volume = 1.0
        }
    }

    /// mapSound の音量をフェードさせる
    private func fadeMapVolume(to target: Float, duration: TimeInterval) {
        // 既存フェードは停止
        mapFadeTimer?.invalidate()
        mapFadeTimer = nil

        // ここでは currentBGM は見ない（map 以外でも呼ばれていたら何もしない仕様でも十分）
        guard let player = bgmPlayer else {
            return
        }

        let startVolume = player.volume
        let steps = 20
        let interval = duration / Double(steps)
        var currentStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            guard let self = self,
                  let p = self.bgmPlayer else {
                t.invalidate()
                return
            }

            let progress = Double(currentStep) / Double(steps)
            let newVolume = startVolume + Float(progress) * (target - startVolume)
            p.volume = max(0.0, min(1.0, newVolume))

            currentStep += 1
            if currentStep > steps {
                t.invalidate()
                self.mapFadeTimer = nil
                p.volume = max(0.0, min(1.0, target))
            }
        }

        mapFadeTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // turnSound が鳴り終わったら mapSound をフェードバック
        if player === turnPlayer {
            turnPlayer = nil

            if currentBGM == .map, bgmPlayer != nil {
                fadeMapVolume(to: 1.0, duration: 0.5)  // 0.5秒で元の音量へ
            }
        }
    }
    
    func playDiceFixSE() {
        playSE(named: "diceSound")   // 実際のファイル名に合わせてください
    }
}

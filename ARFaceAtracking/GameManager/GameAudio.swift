//
//  GameAudio.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/3/29.
//

import Foundation
import AVFoundation

class GameAudio {
    
    static private var playerDic = [AudioName: [AVAudioPlayer]]()
    
    static private var backgroundAudio: AVAudioPlayer?
    
    private init() {}
    
    static var share: GameAudio = {
        let audio = GameAudio()
        GameAudio.loadAudio()
        return audio
    }()
    
    static private func loadAudio() {
        for audio in AudioName.allCases {
            guard let path = Bundle.main.path(forResource: audio.rawValue, ofType: "mp3", inDirectory: "mp3") else { continue }
            let url = URL(fileURLWithPath: path)
            do {
                var players: [AVAudioPlayer] = []
                for _ in 0..<audio.num {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players.append(player)
                }
                GameAudio.playerDic[audio] = players
            } catch let err {
                print(err.localizedDescription)
            }
        }
        print("load Mp3 Success!")
    }
    
    func playAudio(audio: AudioName) {
        guard GameAudio.playerDic.keys.contains(audio)else { return }
        
        for player in GameAudio.playerDic[audio]! {
            if !player.isPlaying {
                player.prepareToPlay()
                player.play()
                return
            }
        }
    }
    
    func backGroundAudio(audio: BackgourdAudio) {
        if audio == .none {
            GameAudio.backgroundAudio = nil
            return
        }
        
        guard let path = Bundle.main.path(forResource: audio.rawValue, ofType: "mp3", inDirectory: "mp3") else { return }
        let url = URL(fileURLWithPath: path)
        do {
            GameAudio.backgroundAudio = try AVAudioPlayer(contentsOf: url)
            GameAudio.backgroundAudio?.numberOfLoops = audio.playTime
            GameAudio.backgroundAudio?.prepareToPlay()
            GameAudio.backgroundAudio?.play()
        } catch let err {
            print(err.localizedDescription)
        }
    }
}


enum AudioName: String, CaseIterable {
    case new = "new"
    case die = "die"
    case attack = "bomb"
    case recover = "recover"
    
    var num: Int {
        switch self {
        case .new: return 3
        case .die: return 3
        case .attack: return 3
        case .recover: return 1
        }
    }
}

enum BackgourdAudio: String, CaseIterable {
    case begin = "begin"
    case back = "background"
    case win = "win"
    case error = "error"
    case none
    
    var playTime: Int {
        switch self {
        case .begin: return 3
        case .back: return -1
        case .win: return 4
        case .error: return 0
        default: return 1
        }
    }
}

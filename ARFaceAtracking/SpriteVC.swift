//
//  SpriteVC.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/17.
//

import UIKit
import SpriteKit

class SpriteVC: UIViewController {
    
    var enableGesture = true
    var gestureView = GestureDrawView(frame: UIScreen.main.bounds)
    
    var gameScene = GameScene()
    lazy var skView: SKView = {
        let skView = SKView(frame: self.view.bounds)
        skView.presentScene(gameScene)
        skView.showsNodeCount = true
        return skView
    }()
    lazy var settingView: GameSettingView = {
        let settingView = GameSettingView()
        settingView.viewDelegate = self
        return settingView
    }()
    lazy var settingButton: UIButton = {
        let button = UIButton(frame: CGRect(x: self.view.bounds.width - 120, y: 30, width: 60, height: 60))
        button.tag = 10
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 10
        button.layer.masksToBounds = true
        button.setImage(UIImage(systemName: "slider.horizontal.3")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(setGame), for: .touchDown)
        return button
    }()
    
    override func viewDidLoad() {
        setUpGame()
        
        gameScene.startGame()
    }
    
    func setUpGame() {
        view.addSubview(skView)
        view.addSubview(gestureView)
        view.addSubview(settingButton)
        view.addSubview(settingView)
        
        let gameGesture = GameGestureRecognizer(target: self, action: #selector(GestureRespondent))
        gameGesture.delegate = self
        view.addGestureRecognizer(gameGesture)
    }
    
    @objc func setGame() {
        if GameCenter.shared.gameState == .running {
            GameCenter.shared.gameState = .paused
        }
        
        self.settingView.open()
        self.gameScene.pauseGame()
    }
    
    @objc func GestureRespondent(sender: GameGestureRecognizer) {
        gestureView.updatePath(p: sender.path, color: sender.result.color)
        if sender.state == .ended {
            gestureView.showResult(type: sender.result)
        }
    }
}


extension SpriteVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard GameCenter.shared.gameState == .running else { return false }
        guard self.enableGesture, !(touch.view is UIButton) else { return false }
        
        let tag = touch.view?.tag ?? 0
        return tag < 5
    }
}


extension SpriteVC: SettingViewDelegate {
    func settingViewClose() {
        if GameCenter.shared.gameState == .paused {
            self.gameScene.continueGame()
        }
    }
    
    func restartGame() {
        self.gameScene.startGame()
    }
}

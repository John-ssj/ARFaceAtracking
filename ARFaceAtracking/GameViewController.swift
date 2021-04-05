//
//  GameViewController.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/3/30.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var gestureView = GestureDrawView(frame: UIScreen.main.bounds)
    
    var gameScene = GameScene()
    lazy var skView: SKView = {
        let skView = SKView(frame: self.view.bounds)
        skView.presentScene(gameScene)
        skView.showsFPS = true
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
        setUpGameView()
        
        gameScene.startGame()
//        autoPlay()
    }
    
    //MARK: - 自动游戏
    private func autoPlay() {
        var i = 0
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            guard let sign = ResultType(rawValue: i%7+1) else { return }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "gestureSign"), object: self, userInfo: ["sign" : sign.stringValue])
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "gestureSign"), object: self, userInfo: ["sign" : sign.stringValue])
            i+=1
        }
    }
    
    func setUpGameView() {
        view.addSubview(skView)
        view.addSubview(gestureView)
        view.addSubview(settingButton)
        view.addSubview(settingView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GameEnd), name: NSNotification.Name("GameState_Changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OpenDesignView), name: NSNotification.Name("OpenDesignView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StartGame), name: NSNotification.Name("StartGame"), object: nil)
        
        let gameGesture = GameGestureRecognizer(target: self, action: #selector(GestureRespondent))
        gameGesture.delegate = self
        view.addGestureRecognizer(gameGesture)
    }
    
    @objc func setGame() {
        guard GameCenter.shared.gameState == .running else { return }
        GameCenter.shared.gameState = .paused
        
        self.settingView.open()
        self.gameScene.pauseGame()
    }
    
    @objc func GameEnd() {
        guard GameCenter.shared.gameState == .end else { return }
        self.settingView.open()
    }
    
    @objc func StartGame() {
        self.gameScene.startGame()
    }
    
    @objc func OpenDesignView() {
        let designVC = UserDesignVC()
        designVC.modalPresentationStyle = .fullScreen
        self.present(designVC, animated: true, completion: nil)
    }
    
    @objc func GestureRespondent(sender: GameGestureRecognizer) {
        gestureView.updatePath(p: sender.path, color: sender.result.color)
        if sender.state == .ended {
            gestureView.showResult(type: sender.result)
        }
    }
}


extension GameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //手势识别，只在游戏运行时，对tag小于5的view生效
        guard GameCenter.shared.gameState == .running,
              !(touch.view is UIButton) else { return false }
        
        let tag = touch.view?.tag ?? 0
        return tag < 5
    }
}


extension GameViewController: SettingViewDelegate {
    func settingViewClose() {
        if GameCenter.shared.gameState == .paused {
            self.gameScene.continueGame()
        }
    }
    
    func restartGame() {
        self.gameScene.startGame()
    }
}

//
//  MagicianNode.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/23.
//

import SpriteKit

class MagicianNode: SKSpriteNode {
    
    private var scale = 1.6
    private var magicianTexture: SKTexture?
    private lazy var magicianSize = CGSize(width: 140*scale, height: 170*scale)
    private var magicWandNode: SKSpriteNode?
    private var magicWandAction: SKAction?
    
    convenience init() {
        self.init(color: .clear, size: CGSize.zero)
        if let path = Bundle.main.path(forResource: "magician", ofType: "png", inDirectory: "png"), let image = UIImage(contentsOfFile: path){
            magicianTexture = SKTexture(image: image)
            self.texture = magicianTexture
        }
        setUpMagicWand()
        self.size = magicianSize
        NotificationCenter.default.addObserver(self, selector: #selector(moveMagicWand), name: NSNotification.Name(rawValue: "gestureSign"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(beAttacked(noti:)), name: NSNotification.Name(rawValue: "Blood_Changed"), object: nil)
    }
    
    private func setUpMagicWand() {
        guard let path = Bundle.main.path(forResource: "giphy3", ofType: "gif", inDirectory: "gif") else {
            print("could not load Magic Wand in this path")
            return
        }
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
            let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { return }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        let frameTime = TimeInterval(0.8 / CGFloat(imageCount))
        self.magicWandAction =  SKAction.animate(with: images.map {SKTexture(image: $0)}, timePerFrame: frameTime)
        
        if let image = images.first{
            let texture = SKTexture(image: image)
            magicWandNode = SKSpriteNode(texture: texture, size: CGSize(width: 50*scale, height: 50*scale))
            magicWandNode?.position = CGPoint(x: -48*scale, y: 20*scale)
            self.addChild(magicWandNode!)
        }
    }
    
    @objc private func moveMagicWand() {
        if magicWandAction != nil {
            self.magicWandNode?.run(magicWandAction!, withKey: "magicWandAction")
        }
    }
    
    @objc private func beAttacked(noti: Notification) {
        guard let beAtt = noti.userInfo?["attack"] as? Bool, beAtt else { return }
        
        self.removeAction(forKey: "beAtacked")
        GameAudio.share.playAudio(audio: .attack)
        self.run(SKAction.scale(to: 0.8, duration: 0.1), withKey: "beAtacked")
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
            self.run(SKAction.scale(to: 1, duration: 0.2), withKey: "beAtacked")
        }
    }
    
    //游戏lost时,
    func dieLost() {
        let dismissAction = SKAction.fadeAlpha(to: 0, duration: 0.8)
        dismissAction.timingMode = .easeIn
        self.physicsBody = nil
        //取消移动动作，先放大，再爆炸，慢慢缩小，最后消失。
        let scaleBig = SKAction.scale(to: 1.3, duration: 0.4)
        scaleBig.timingMode = .easeIn
        self.run(scaleBig) {
            GameAudio.share.playAudio(audio: .attack)
            self.texture = SKTexture(imageNamed: "star")
            self.run(dismissAction) {
                self.removeFromParent()
            }
        }
    }
}

//
//  SymbolNode.swift
//  ARFaceAtracking
//
//  Created by 史导的Mac on 2021/4/5.
//

import SpriteKit

class SymbolNode: SKSpriteNode {
    private var labelNode: SKLabelNode!
    private var textureNode: SKSpriteNode!
    private var maskNode: SKShapeNode!
    private var atackTimer: Timer! // 计时器。每0.5秒进行一次碰撞检测
    private var specialTimer: Timer?
    /** Node符号 */
    private var symbols: String! {
        didSet{
            self.labelNode.attributedText = generateAttributed()
        }
    }
    
    private var loadSuccess = false
    
    
    //MARK: - public func
    
    /*
     * 加载图片资源
     */
    /// - parameter textures: 参数textures的含义描述
    func setUpGif(with textures: [SKTexture], frameTime: TimeInterval) {
        self.textureNode.run(SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: frameTime)), withKey: "gifAction")
        self.loadSuccess = true
    }

    func setUpPng(with texture: SKTexture) {
        self.textureNode.texture = texture
        self.loadSuccess = true
    }
    
    //MARK: - private func
    
    /** 设置符号Label */
    private func setUpLabelNode() {
        labelNode = SKLabelNode()
        labelNode.alpha = 0
        labelNode.position = CGPoint(x: 0, y: self.textureNode.size.height/2+15)
        labelNode.zPosition = 1
        self.addChild(labelNode)
    }
    
    /** 将箭头符号变成富文本 */
    private func generateAttributed() -> NSAttributedString? {
        guard self.symbols != "" else { return nil }
        
        let attrStr = NSMutableAttributedString(string: self.symbols)
        
        //设置字体
        let fontAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28, weight: .heavy)]
        attrStr.addAttributes(fontAttribute, range: NSRange(location: 0, length: attrStr.length))
        
        //设置颜色
        for i in 0..<self.symbols.count {
            let color = ResultType(stringValue: self.symbols[i]).color
            let colorAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: color]
            attrStr.addAttributes(colorAttribute, range: NSRange(location: i, length: 1))
        }
        return attrStr
    }
}

//
//  SKVirusNode.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/22.
//

import SpriteKit

public class SKVirusNode: SKSpriteNode {
    
    var virusHierarchy = 1 //第几代virus（部分virus需要）
    private var virusInfo = VirusInfo()
    private var labelNode = SKLabelNode()
    private var magicianP: CGPoint { GameCenter.shared.magicianPoint }
    private var textureNode: SKSpriteNode!
    private var maskNode: SKShapeNode!
    private var atackTimer: Timer! // 计时器。每0.5秒进行一次碰撞检测
    private var specialTimer: Timer?
    private var gameLabel: String! {
        didSet{
            self.labelNode.attributedText = generateAttributed()
        }
    }
    // 病毒被消灭，需要删除
    private var shouldDismiss = false {
        didSet{
            dismissAction()
        }
    }
    // gif/png资源在家成功，运行动画
    private var loadSuccess = false {
        didSet{
            if loadSuccess == true {
                self.labelNode.run(SKAction.fadeAlpha(to: 1, duration: 0.6))
                runMoveAction()
            }
        }
    }
    // 病毒名字，每次名字改变时都会重新加载gif资源
    var virusName: VirusNames! {
        didSet{
            setUpVirus()
        }
    }
    
    convenience init(virusName: VirusNames) {
        DispatchQueue.global().async {
            _ = SKVirusNode.pngResource
            _ = SKVirusNode.gifResource
        }
        self.init(color: .clear, size: CGSize.zero)
        self.virusName = virusName
        setUpVirus()
        setUpGameLabel()
        setUpNotifications()
    }
    
    deinit {
        self.specialTimer?.invalidate()
    }
}


extension SKVirusNode {
    
    static let gifResource: [VirusNames: [SKTexture]] = {
        var dic = [VirusNames: [SKTexture]]()
        for virus in VirusNames.allCases {
            if virus == .normalVirus { continue }
            let resourceName = virus.rawValue
            guard let path = Bundle.main.path(forResource: resourceName, ofType: "gif", inDirectory: "gif") else {
                print("Gif does not exist at that path")
                continue
            }
            let url = URL(fileURLWithPath: path)
            guard let gifData = try? Data(contentsOf: url),
                  let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { continue }
            var images = [UIImage]()
            let imageCount = CGImageSourceGetCount(source)
            for i in 0 ..< imageCount {
                if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: image))
                }
            }
            let textures = images.map {SKTexture(image: $0)}
            dic[virus] = textures
        }
        print("gifResource loadsuccess!")
        return dic
    }()

    static let pngResource: [SKTexture] = {
        var dic = [SKTexture]()
        for num in 1...8 {
            let name = "virus\(num)"
            guard let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "png"),
                  let image = UIImage(contentsOfFile: path) else { continue }
            dic.append(SKTexture(image: image))
        }
        return dic
    }()

    // 加载gif资源
    private func loadTextureGif() {
        guard let textures = SKVirusNode.gifResource[self.virusName] else { return }
        let frameTime = self.virusInfo.frameDuration
        self.loadSuccess = true
        self.textureNode.run(SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: frameTime)), withKey: "gifAction")
    }

    //加载png资源
    private func loadPng() -> SKTexture? {
        self.loadSuccess = true
        return SKVirusNode.pngResource.randomElement()
    }
    
    // 生成箭头符号
    private func generatingGameLabel(lenth: Int, isEasy: Bool) -> String {
        var label = ""
        let typeList = isEasy ? ResultType.easyTypes : ResultType.allVirusTypes
        for _ in 0..<lenth {
            label += typeList.randomElement()!
        }
        return label
    }
    
    // 将箭头符号变成富文本
    private func generateAttributed() -> NSAttributedString? {
        guard gameLabel != "" else { return nil }
        let attrStr = NSMutableAttributedString(string: gameLabel)
        let fontAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28, weight: .heavy)]
        attrStr.addAttributes(fontAttribute, range: NSRange(location: 0, length: attrStr.length))
        for i in 0..<gameLabel.count {
            let color = ResultType(stringValue: gameLabel[i]).color
            let colorAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: color]
            attrStr.addAttributes(colorAttribute, range: NSRange(location: i, length: 1))
        }
        return attrStr
    }
    
    // 设置符号Label
    private func setUpGameLabel() {
        self.gameLabel = generatingGameLabel(lenth: self.virusInfo.lenth, isEasy: self.virusInfo.isEasy)
        self.addChild(labelNode)
        labelNode.alpha = 0
        labelNode.position = CGPoint(x: 0, y: self.virusInfo.radius+15)
        labelNode.zPosition = 1
    }
    
    private func setUpNotifications() {
        //接收检测手势
        NotificationCenter.default.addObserver(self, selector: #selector(gestureSign(noti:)), name: NSNotification.Name("gestureSign"), object: nil)
        atackTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(atackMagician), userInfo: nil, repeats: true)
        atackTimer.fire()
    }
    
    // 自动移动
    private func runMoveAction() {
        let presentPos = self.position
        let distance = hypot(self.magicianP.x-presentPos.x,
                             self.magicianP.y-presentPos.y)
        
        let action = SKAction.move(to: self.magicianP, duration: TimeInterval(distance / virusInfo.moveSpeed))
        self.run(action, withKey: "autoMove")
    }
    
    // 手势识别后更新病毒剩余的virus箭头符号
    @objc private func gestureSign(noti: Notification) {
        guard self.loadSuccess == true,
            self.shouldDismiss == false,
            let sign = noti.userInfo?["sign"] as? String,
            ResultType.allVirusTypes.contains(sign) else { return }
        let firstSign = String(self.gameLabel.prefix(1))
        if firstSign == sign {
            self.gameLabel = String(self.gameLabel.dropFirst())
            if self.gameLabel != "" {
                self.maskNode.fillColor = UIColor.red
                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
                    self.maskNode.fillColor = UIColor.clear
                }
            }else{
                if self.gameLabel == "" {
                    GameCenter.shared.addScore(virus: self.virusName)
                    self.shouldDismiss = true
                }
            }
        }
        return
    }
    
    // 检测是否与Magician碰撞
    @objc private func atackMagician() {
        guard GameCenter.shared.gameState == .running,
              self.shouldDismiss == false else { return }
        let distance = hypot(self.magicianP.x-self.position.x,
                             self.magicianP.y-self.position.y)
        
        if distance < self.virusInfo.radius + 70 {
            GameCenter.shared.AttackMagician()
            self.shouldDismiss = true
        }
    }
    
    private func setUpVirus() {
        self.virusInfo.setUpInfo(type: virusName)
        // 判断是gif还是图片
        textureNode = SKSpriteNode()
        textureNode.size = self.virusInfo.virusSize
        if virusInfo.animated {
            textureNode.removeAction(forKey: "gifAction")
            loadTextureGif()
            self.addChild(textureNode)
            stealth_greenBigEye()
            division_colorfulBeauty()
            childs_greenFatParents()
        } else {
            // 静态图片初始化
            textureNode.texture = loadPng()
            textureNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: 3, duration: TimeInterval(Int.random(from: 2, to: 5)))), withKey: "PngAction")
            self.addChild(textureNode)
        }
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.virusInfo.radius*0.7) // 照片尺寸大于实际显示的virus大小
        self.physicsBody?.categoryBitMask = self.virusName.bitmask
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.mass = pow(self.virusInfo.radius, 2)
        
        maskNode = SKShapeNode(circleOfRadius: textureNode.size.width/2)
        maskNode.fillColor = UIColor.clear
        maskNode.strokeColor = UIColor.clear
        maskNode.alpha = 0.6
        self.textureNode.addChild(maskNode)
    }
    
    private func dismissAction() {
        backWard_King_Queen()
        if shouldDismiss {
            GameAudio.share.playAudio(audio: .die)
            self.specialTimer?.invalidate()
            if self.virusName == .greenBigEye {
                self.removeAction(forKey: "stealth_greenBigEye")
                self.alpha = 1
            }
            let dismissAction = SKAction.fadeAlpha(to: 0, duration: 1.2)
            dismissAction.timingMode = .easeIn
            self.physicsBody = nil
            atackTimer.invalidate() // 停止攻击魔术师检测
            //取消移动动作，先放大，再爆炸，慢慢缩小，最后消失。
            self.removeAction(forKey: "autoMove")
            let scaleBig = SKAction.scale(to: 1.3, duration: 0.8)
            scaleBig.timingMode = .easeIn
            self.labelNode.run(dismissAction)
            self.textureNode.run(scaleBig) {
                self.textureNode.removeAction(forKey: "gifAction")
                self.textureNode.removeAction(forKey: "pngAction")
                self.blast_greenBomb()
                if self.virusName != .greenBomb {
                    self.textureNode.texture = SKTexture(imageNamed: "star")
                }
                self.run(dismissAction) {
                    self.revive_redBigEye()
                    self.removeFromParent()
                }
            }
        }
    }
    
    func dieLost() {
        self.specialTimer?.invalidate()
        if self.virusName == .greenBigEye {
            self.removeAction(forKey: "stealth_greenBigEye")
            self.alpha = 1
        }
        let dismissAction = SKAction.fadeAlpha(to: 0, duration: 0.8)
        dismissAction.timingMode = .easeIn
        self.physicsBody = nil
        atackTimer.invalidate() // 停止攻击魔术师检测
        //先放大，再爆炸，慢慢缩小，最后消失。
        let scaleBig = SKAction.scale(to: 1.3, duration: 0.4)
        scaleBig.timingMode = .easeIn
        self.labelNode.run(dismissAction)
        self.textureNode.run(scaleBig) {
            self.textureNode.removeAction(forKey: "gifAction")
            self.textureNode.removeAction(forKey: "pngAction")
            self.blast_greenBomb()
            GameAudio.share.playAudio(audio: .die)
            self.textureNode.texture = SKTexture(imageNamed: "star")
            self.run(dismissAction) {
                self.revive_redBigEye()
                self.removeFromParent()
            }
        }
    }
}


// MARK: - virus特殊技能
extension SKVirusNode {
    
    /*
    //自定义路径 virus1
    隐形 virus2
    爆炸 virus3
    生成小病毒 virus4
    复活 virus5
    分裂 virus6
    3条血，每条血结束后退 virus7, virus8
    */
    
    private func stealth_greenBigEye() {
        guard self.virusName == .greenBigEye else { return }
        
        var state = true
        self.specialTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            self.run(SKAction.fadeAlpha(to: state ? 0 : 0.8, duration: 2), withKey: "stealth_greenBigEye")
            state.toggle()
        }
        self.specialTimer?.fire()
    }
    
    private func blast_greenBomb() {
        guard self.virusName == .greenBomb ,
              self.shouldDismiss == true else { return }
        self.textureNode.texture = nil
        NotificationCenter.default.post(name: NSNotification.Name("add_blast"), object: nil, userInfo: ["point": self.position])
    }
    
    private func childs_greenFatParents() {
        guard self.virusName == .greenFatParents,
              self.shouldDismiss == false else { return }
        
        var child = 1
        
        self.specialTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            guard self.virusHierarchy <= 12 else {
                self.specialTimer?.invalidate()
                return
            }
            
            let de = atan((self.magicianP.y-self.position.y) /
                            (self.magicianP.x-self.position.x))
            
            var targetP = self.position
            targetP.x += 70 * cos(de)
            targetP.y += 70 * sin(de)
            targetP.x -= 100 * cos(de + CGFloat.pi/3*CGFloat(child/2)*((child % 2)==1 ? 1: -1))
            targetP.y -= 100 * sin(de + CGFloat.pi/3*CGFloat(child/2)*((child % 2)==1 ? 1: -1))
            child += 1
            
            let bigAction = SKAction.scale(to: 1.2, duration: 1)
            bigAction.timingMode = .easeIn
            let smallAction = SKAction.scale(to: 1, duration: 0.8)
            smallAction.timingMode = .easeOut
            self.run(bigAction){
                self.run(smallAction)
            }
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                NotificationCenter.default.post(name: NSNotification.Name("add_Virus"), object: nil, userInfo: ["virusInfo" : [VirusNames.normalVirus : 1], "point": targetP])
            }
            
            self.virusHierarchy += 1
        }
    }
    
    private func revive_redBigEye() {
        guard self.virusHierarchy == 1,
              self.virusName == .redBigEye ,
              self.shouldDismiss == true else { return }
        guard self.isPaused == false else { return }
        NotificationCenter.default.post(name: NSNotification.Name("add_Virus"), object: nil, userInfo: ["virusInfo" : [VirusNames.redBigEye : 1], "point": self.position, "hierarchy" : self.virusHierarchy])
    }
    
    private func division_colorfulBeauty() {
        guard self.virusName == .colorfulBeauty,
              self.shouldDismiss == false else { return }
        
        var child = 1
        
        self.specialTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            guard self.virusHierarchy <= 4 else {
                self.specialTimer?.invalidate()
                return
            }
            
            let de = atan((self.magicianP.y-self.position.y) /
                            (self.magicianP.x-self.position.x))
            
            var targetP = self.position
            targetP.x += 70 * cos(de)
            targetP.y += 70 * sin(de)
            targetP.x -= 110 * cos(de + CGFloat.pi/3*(CGFloat(child)-2.5))
            targetP.y -= 110 * sin(de + CGFloat.pi/3*(CGFloat(child)-2.5))
            child += 1
            
            let bigAction = SKAction.scale(to: 1.6, duration: 1)
            bigAction.timingMode = .easeIn
            let smallAction = SKAction.scale(to: 1, duration: 0.2)
            smallAction.timingMode = .easeOut
            self.run(bigAction){
                self.run(smallAction)
            }
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                guard self.isPaused == false else { return }
                NotificationCenter.default.post(name: NSNotification.Name("add_Virus"), object: nil, userInfo: ["virusInfo" : [VirusNames.colorfulBeauty : 1], "point": targetP, "hierarchy" : self.virusHierarchy])
            }
            
            self.virusHierarchy += 1
        }
    }
    
    private func backWard_King_Queen() {
        guard (self.virusName == .greenKing || self.virusName == .purpleQueen),
              self.virusHierarchy < 3,
              self.shouldDismiss == true else { return }
        
        self.shouldDismiss = false
        self.virusHierarchy += 1
        
        guard self.shouldDismiss == false else { return }
        let distance = hypot(self.magicianP.x-self.position.x,
                             self.magicianP.y-self.position.y)
        
        self.removeAction(forKey: "autoMove")
        var targetP = self.position
        if distance < 180 {
            targetP.x -= 300*(self.magicianP.x-self.position.x)/distance
            targetP.y -= 300*(self.magicianP.y-self.position.y)/distance
        } else {
            targetP.x -= 200*(self.magicianP.x-self.position.x)/distance
            targetP.y -= 200*(self.magicianP.y-self.position.y)/distance
        }
        let backAction = SKAction.move(to: targetP, duration: 0.3)
        backAction.timingMode = .easeOut
        self.run(backAction) {
            self.virusInfo.moveSpeed -= 2
            self.gameLabel = self.generatingGameLabel(lenth: self.virusInfo.lenth, isEasy: self.virusInfo.isEasy)
            self.runMoveAction()
        }
    }
}

//
//  SymbolNode.swift
//  ARFaceAtracking
//
//  Created by 史导的Mac on 2021/4/5.
//

import SpriteKit

class SymbolNode: SKSpriteNode {
    
    
    //MARK: - 状态标记变量
    
    /** Node状态 */
    var nodeState: NodeState = .setup { didSet{ stateChange() } }
    /** 标记符号 */
    var symbols: String! { didSet{ updateAttributedLabel() } }
    
    /** 是否接收标记符号 */
    var receiveSymbols = true
    /** 是否检测碰撞 */
    var attackTest = true
    /** 尺寸大小 */
    var textureSize = CGSize(width: 80, height: 80) { didSet{ setSize() } }
    /** 自动移动方式:向targetP移动，向某点移动，不移动 */
    var autoMove = MovingMode.noMove { didSet{ autoMoveAction() } }
    /** 移动方向 */
    var movingDir: CGVector? = nil { didSet{ autoMoveAction() } }
    /** 移动速度 */
    var movingSpeed: CGFloat = 50 { didSet{ autoMoveAction() } }
    /** 是否需要physicalBody */
    var createPhysicBody = true { didSet{ setUpPhysicsBody() } }
    /** 首标记被清除后，是否显示朦层变化 */
    var changeMask = false
    
    /** target坐标 */
    private var targetP: CGPoint { GameCenter.shared.magicianPoint }
    /** Node与target的距离 */
    var distance: CGFloat { hypot(self.targetP.x-self.position.x,
                                  self.targetP.y-self.position.y) }
    
    /** 每0.5秒进行一次碰撞检测 */
    private var atackTimer: Timer?
    
    
    //MARK: - SubNodes
    
    /** 手势标记Node */
    private var labelNode: SKLabelNode!
    /** 图片展示Node */
    private var textureNode: SKSpriteNode!
    /** 朦层 */
    private var maskNode: SKShapeNode!
    
    
    //MARK: - 初始化
    init(receiveSym: Bool = true, attack: Bool = true, move: MovingMode = .noMove, changeM: Bool = false, physicBody: Bool = true) {
        super.init(texture: nil, color: .clear, size: .zero)
        
        self.receiveSymbols = receiveSym
        self.attackTest = attack
        self.autoMove = move
        self.changeMask = changeM
        self.createPhysicBody = physicBody
        
        setUpNodes()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.atackTimer?.invalidate()
    }
    
}


extension SymbolNode{
    
    //MARK: - setUpNode
    
    /** 初始化所有Node */
    private func setUpNodes() {
        //加载完成前Node不可见
        self.isHidden = true
        
        labelNode = SKLabelNode()
        labelNode.position = CGPoint(x: 0, y: 0)
        labelNode.zPosition = 1
        self.addChild(labelNode)
        
        textureNode = SKSpriteNode()
        self.addChild(textureNode)
        
        maskNode = SKShapeNode(circleOfRadius: self.textureSize.width/2)
        maskNode.fillColor = UIColor.clear
        maskNode.strokeColor = UIColor.clear
        maskNode.alpha = 0.6
        self.textureNode.addChild(maskNode)
        
        setSize()
        setUpPhysicsBody()
        
        self.atackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            guard self.attackTest, self.nodeState == .running else { return }
            if self.distance <= GameCenter.shared.magicianRadius + self.size.width*1.2 {
                self.attackMagician()
            }
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveSign(noti:)), name: NSNotification.Name("gestureSign"), object: nil)
    }
    
    /** 设置size */
    /// - parameter size: 图片的size
    private func setSize() {
        self.textureNode?.size = self.textureSize
        self.size = CGSize(width: self.textureSize.width+30, height: self.textureSize.height+30)
        
        //更新标记符号的位置
        self.labelNode.position = CGPoint(x: 0, y: self.textureNode.size.height/2+15)
        
        //改变朦层的大小
        self.maskNode.path = CGPath(ellipseIn: CGRect(origin: CGPoint.zero, size: self.textureSize), transform: nil)
        
        //改变物理body大小
        self.setUpPhysicsBody()
    }
    
    /** 将符号变成富文本显示 */
    private func updateAttributedLabel(){
        guard self.labelNode != nil else { return }
        guard self.symbols != "" else {
            self.labelNode.attributedText = nil
            return
        }
        
        let attrStr = NSMutableAttributedString(string: self.symbols)
        
        //设置字体
        let fontAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 28, weight: .heavy)]
        attrStr.addAttributes(fontAttribute, range: NSRange(location: 0, length: attrStr.length))
        
        //每个标记设置不同的颜色
        for i in 0..<self.symbols.count {
            let color = ResultType(stringValue: self.symbols[i]).color
            let colorAttribute: [NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor: color]
            attrStr.addAttributes(colorAttribute, range: NSRange(location: i, length: 1))
        }
        
        //更新富文本
        self.labelNode.attributedText = attrStr
    }
    
    /** 接收标记通知，删除首标记 */
    @objc private func receiveSign(noti: Notification) {
        guard self.nodeState == .running, self.receiveSymbols,
              let sign = noti.userInfo?["sign"] as? String,
              ResultType.allVirusTypes.contains(sign) else { return }
        
        let firstSign = String(self.symbols.prefix(1))
        if firstSign == sign {
            self.symbols = String(self.symbols.dropFirst())
            if self.symbols != "" {
                //首标记被清除
                symbolCleaned()
            }else{
                //所有标记被清除
                self.nodeState = .disappearing
            }
        }
        return
    }
    
    
    //MARK: - nodeMove
    
    /** 自动移动:向targetP移动，向某点移动，不移动 */
    private func autoMoveAction() {
        self.removeAction(forKey: "moveAction")
        guard self.autoMove != .noMove, self.nodeState == .running else { return }
        
        //向targetP移动
        if self.autoMove == .toPoint {
            let moveAction = SKAction.move(to: self.targetP, duration: TimeInterval(distance / self.movingSpeed))
            self.run(moveAction, withKey: "moveAction")
        }
        
        //向某方向移动
        if self.autoMove == .toDir {
            guard let dir = self.movingDir else { return }
            let lenth = hypot(dir.dx, dir.dy)
            let totalLenth = hypot(UIScreen.main.bounds.width, UIScreen.main.bounds.height)*2
            let alpha = totalLenth/lenth
            let moveAction = SKAction.move(by: CGVector(dx: dir.dx*alpha, dy: dir.dy*alpha),
                                           duration: TimeInterval(totalLenth/self.movingSpeed))
            let moveAndOutAction = SKAction.sequence([moveAction,
                                       .run{ self.nodeState = .disappearing }])
            self.run(moveAndOutAction, withKey: "moveAction")
        }
    }
    
    /** 生成物理模型，防止重叠 */
    private func setUpPhysicsBody() {
        guard self.createPhysicBody else {
            self.physicsBody = nil
            return
        }
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.textureSize.width * 0.7)
        self.physicsBody?.categoryBitMask = 1
        self.physicsBody?.isDynamic = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.mass = pow(self.textureSize.width, 2)
    }
    
    private func stateChange() {
        switch self.nodeState {
        case .setup: loading()
        case .running: loadSuccess()
        case .disappearing: nodeDisappear()
        case .end: releaseNode()
        }
    }
}


//MARK: - public func
extension SymbolNode{
    
    /** 随机符号字符串 */
    final func RandomSymbols(lenth: Int, isEasy: Bool) -> String {
        var label = ""
        let typeList = isEasy ? ResultType.easyTypes : ResultType.allVirusTypes
        for _ in 0..<lenth {
            label += typeList.randomElement()!
        }
        return label
    }
    
    /** 定制符号字符串 */
    /// - parameter str: 输入字符串，
    /// 属于allVirusTypes则不变，
    /// "?"变成任意type，
    /// "E"变成简单type，
    /// "H"变成复杂tpye，
    /// "."变成前一个type，
    /// 其他跳过。
    final func CustomizeSymbols(_ str: String) -> String {
        var label = ""
        var pre = ResultType.up.stringValue
        for i in 0..<str.count {
            if ResultType.allVirusTypes.contains(str[i]) { pre = str[i] }
            switch str[i] {
            case "?": pre = ResultType.allVirusTypes.randomElement()!
            case "E": pre = ResultType.easyTypes.randomElement()!
            case "H": pre = ResultType.hardTypes.randomElement()!
            case ".": break
            default: continue
            }
            label += pre
        }
        return label
    }
    
    /** 设置gif播放,添加textureAction */
    /// - parameter textures: gif图片数组
    /// - parameter frameTime: 每张gif图片刷新时间间隔
    /// - parameter size: 图片大小，默认为80*80
    final func setUpGif(with textures: [SKTexture], frameTime: TimeInterval, size: CGSize? = nil) {
        self.textureNode?.run(SKAction.repeatForever(SKAction.animate(with: textures, timePerFrame: frameTime)), withKey: "textureAction")
        self.nodeState = .running
        
        if size != nil { self.textureSize = size! }
    }

    /** 设置图片 */
    /// - parameter texture: 图片
    /// - parameter size: 图片大小，默认为80*80
    final func setUpPng(with texture: SKTexture, size: CGSize? = nil) {
        self.textureNode?.texture = texture
        self.nodeState = .running
        
        if size != nil { self.textureSize = size! }
    }
    
    /** 直接向目标移动 */
    final func moveToTarget(speed: CGFloat) {
        self.removeAction(forKey: "moveAction")
        let moveAction = SKAction.move(to: self.targetP, duration: TimeInterval(distance / speed))
        self.run(moveAction, withKey: "moveAction")
    }
    
    /** 首标记被清除 */
    //TODO: - override,添加声音等
    func symbolCleaned() {
        guard self.changeMask else { return }
        self.maskNode.fillColor = UIColor.red
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { _ in
            self.maskNode.fillColor = UIColor.clear
        }
    }
    
    /** 加载资源 */
    func loading() {
        //加载过程Node不可见
        self.isHidden = true
    }
    
    /** 图片资源加载成功 */
    func loadSuccess() {
        //使Node可见
        self.isHidden = false
        autoMoveAction()
    }
    
    /** node消失动画 */
    // TODO: - override,添加声音等,需要在函数尾部添加self.nodeState = .end
    // 或者改变nodeState为.running
    @objc func nodeDisappear() {
        self.removeAllActions()
        self.nodeState = .end
    }
    
    /** 释放node */
    func releaseNode() {
        self.removeFromParent()
    }
    
    /** node碰到magician */
    // TODO: - override,添加声音等,需要在函数尾部添加self.nodeState = .end
    func attackMagician() {
        self.nodeState = .end
    }
}


enum NodeState {
    case setup
    case running
    case disappearing
    case end
}

enum MovingMode {
    case toPoint
    case toDir
    case noMove
}

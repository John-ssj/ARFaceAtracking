//
//  GameManager.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/23.
//

import UIKit
import SpriteKit

class GameManager: NSObject {
    // MARK: - 关键变量
    
    /**
     * 是否暂停
     * - 只有当状态是running的时候才不是暂停
     */
    var state: GameState { GameCenter.shared.gameState }
    /** 游戏进行时间 */
    private var time = TimeInterval.zero
    /** 游戏最后的virus出现的时间 */
    private var endTime = TimeInterval.zero
    /** 游戏每秒刷新时钟 */
    private var gameTimer: Timer?
    /** 游戏关卡数据,从GameCenter中获得 */
    private var virusDic: [Int: [VirusNames: Int]] {
        GameCenter.shared.getVirusDic()
    }
    /** 魔术师位置 */
    private var magicianP: CGPoint { GameCenter.shared.magicianPoint }
    /** 魔术师node */
    private var magician: MagicianNode?
    /** 是否可以生产新的blood */
    private var newBlood = true
    /** 游戏是否结束,若结束,则timer不再刷新 */
    private var gameIsOver: Bool {
        GameCenter.shared.gameState == .win || GameCenter.shared.gameState == .lost
    }
    /** 连接manager和Scene的代理 */
    var delegate: GameManagerDelegate!
    
    
    private var width: CGFloat {UIScreen.main.bounds.width}
    private var height: CGFloat {UIScreen.main.bounds.height}
    
    // MARK: - init
    override init() {
        super.init()
        
        setUpNotifications()
    }
    
    
    // MARK: - public函数
    func startGame() {
        guard GameCenter.shared.gameState == .start else { return }
        magician?.removeFromParent()
        magician = MagicianNode()
        if magician != nil {
            magician!.position = magicianP
            self.delegate.addToView(node: magician!)
        }
        
        // 重置游戏数据
        time = TimeInterval.zero
        endTime = TimeInterval(virusDic.keys.max() ?? 0)
        newBlood = true
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(upDataTime), userInfo: nil, repeats: true)
    }
    
    
    // MARK: - private函数
    private func setUpNotifications() {
        // 添加新病毒
        NotificationCenter.default.addObserver(self, selector: #selector(addVirus(noti:)), name: NSNotification.Name(rawValue: "add_Virus"), object: nil)
        // 添加爆炸病毒被消灭后留下阴影
        NotificationCenter.default.addObserver(self, selector: #selector(addBlast(noti:)), name: NSNotification.Name(rawValue: "add_blast"), object: nil)
    }
    
    //MARK: - 主刷新函数
    /** 每秒从dic中更新病毒,并检测是否需要生产blood,判断游戏是否结束 */
    @objc private func upDataTime() {
        //游戏状态为.lost时调用这部分代码
        if GameCenter.shared.gameState == .lost, self.delegate.allVirusDied() {
            self.gameTimer?.invalidate()
            GameCenter.shared.gameState = .end
        }
        //游戏状态为.running时调用这部分代码
        guard self.state == .running, self.magician != nil else { return }
        
        self.time += 1
        if self.newBlood == true, GameCenter.shared.getBlood() < GameCenter.maxBlood, self.time <= self.endTime {
            self.newBlood = false
            let bloodNode = SKBloodNode()
            bloodNode.position = CGPoint.zero
            bloodNode.zPosition = 0.8
            self.delegate.addToView(node: bloodNode)
            Timer.scheduledTimer(withTimeInterval: 25, repeats: false) { _ in
                self.newBlood = true
            }
        }
        if virusDic.keys.contains(Int(self.time)) {
            newVirus()
//            for virus in virusDic[Int(self.time)]! {
//                for _ in 0..<virus.value{
//                    let virusNode = SKVirusNode(virusName: virus.key)
//                    virusNode.position = getRandomVirusP()
//                    self.delegate.addToView(node: virusNode)
//                }
//            }
        }
        if self.time > self.endTime + 3,
           GameCenter.shared.getBlood() > 0,
           self.delegate.allVirusDied() {
            GameCenter.shared.gameState = .win
            self.gameTimer?.invalidate()
        }
    }
    
    // MARK: - 新游戏模式设计
    private func newVirus() {
        createYellowTail()
    }
    
    private func createYellowTail() {
        let oringeP = CGPoint(x: self.width, y: self.height/2)
        for i in 0..<6 {
            let vNum = i<3 ? i : 3
            for j in -vNum...vNum {
                let virusNode = SKVirusNode(virusName: .yellowTail)
                virusNode.position = CGPoint(x: oringeP.x+(virusNode.size.width+50)*CGFloat(i-1),
                                             y: oringeP.y+(virusNode.size.height+50)*CGFloat(j))
                self.delegate.addToView(node: virusNode)
            }
        }
    }
}


// MARK: - 添加viurs和爆炸烟雾
extension GameManager {
    @objc private func addVirus(noti: Notification) {
        guard self.state == .running || self.state == .paused else { return }
        guard let virusList = noti.userInfo?["virusInfo"] as? [VirusNames: Int],
              var point = noti.userInfo?["point"] as? CGPoint else { return }
        let parentHierarchy = (noti.userInfo?["hierarchy"] as? Int) ?? 0
        
        for virus in virusList {
            for _ in 0..<virus.value{
                let virusNode = SKVirusNode(virusName: virus.key)
                virusNode.virusHierarchy += parentHierarchy
                let dir = CGFloat(Int.random(to: 360)) / 360 * 2 * CGFloat.pi
                point.x += 20 * cos(dir)
                point.y += 20 * sin(dir)
                virusNode.position = point
                virusNode.alpha = 0.2
                virusNode.setScale(0.5)
                if self.state == .running {
                    GameAudio.share.playAudio(audio: .new)
                }
                self.delegate.addToView(node: virusNode)
                virusNode.run(SKAction.fadeAlpha(to: 1, duration: 0.6))
                virusNode.run(SKAction.scale(to: 1, duration: 2))
                if self.state != .running {
                    virusNode.isPaused = true
                }
            }
        }
    }
    
    @objc private func addBlast(noti: Notification) {
        guard let point = noti.userInfo?["point"] as? CGPoint else { return }
        
//        let path = CGMutablePath()
//        let r: CGFloat = 50
//        let num = 12
//        path.move(to: CGPoint(x: r, y: 0))
//        for alpha in 1...num {
//            let a = CGFloat(alpha)/CGFloat(num) * 2 * CGFloat.pi
//            let p1 = CGPoint(x: r * cos(a),
//                             y: r * sin(a))
//            let b = CGFloat(alpha*3-1)/CGFloat(3*num) * 2 * CGFloat.pi
//            let dr2 = CGFloat(Int.random(from: -3, to: 4))
//            let p2 = CGPoint(x: (r + dr2) * cos(b),
//                             y: (r + dr2) * sin(b))
//            let c = CGFloat(alpha*3-2)/CGFloat(3*num) * 2 * CGFloat.pi
//            let dr3 = CGFloat(Int.random(from: -3, to: 4))
//            let p3 = CGPoint(x: (r + dr3) * cos(c),
//                             y: (r + dr3) * sin(c))
//            path.addCurve(to: p1, control1: p2, control2: p3)
//        }
//        path.closeSubpath()
        
        let blastNode = SKSpriteNode()
        blastNode.texture = SKTexture(imageNamed: "png/blast")
        blastNode.name = "blastNode"
//        blastNode.path = path
//        blastNode.strokeColor = #colorLiteral(red: 0.7980566621, green: 0.7973025441, blue: 0.1943252981, alpha: 1)
//        blastNode.fillColor = #colorLiteral(red: 0.7980566621, green: 0.7973025441, blue: 0.1943252981, alpha: 1)
        blastNode.zPosition = 2
        blastNode.position = point
        blastNode.setScale(0.3)
        blastNode.alpha = 0.8
        self.delegate.addToView(node: blastNode)
        
        //先放大，保持5秒不变，然后变淡消失。
        let scaleAction = SKAction.scale(to: 3, duration: 0.1)
        scaleAction.timingMode = .easeIn
        let fadeAction = SKAction.fadeAlpha(to: 0, duration: 1)
        fadeAction.timingMode = .easeOut
        let balstAction = SKAction.sequence([scaleAction,
                                                 .wait(forDuration: 5),
                                                 fadeAction,
                                                 .removeFromParent()])
        blastNode.run(balstAction)
    }
    
    // MARK: - new virus生成的位置
    enum Direction {
        case up
        case down
        case left
        case right
    }
    
    private func getRandomVirusP(dir direction: Direction? = nil) -> CGPoint {
        var dir = direction
        if dir == nil {
            // 有1/6的概率从上下出现，其他从左右出现。70%概率从远点那一边出现
            let upOrDown = Int.random(to: 6) == 1
            let normalDir = Int.random(to: 9) < 7
            if upOrDown {
                if self.magicianP.y > UIScreen.main.bounds.height/2 {
                    dir = normalDir ? .down : .up
                }else {
                    dir = normalDir ? .up : .down
                }
            }else {
                if self.magicianP.x > UIScreen.main.bounds.width/2 {
                    dir = normalDir ? .left : .right
                }else {
                    dir = normalDir ? .right : .left
                }
            }
        }
        var virusP = CGPoint.zero
        switch dir {
        case .down:
            virusP = CGPoint(x: Int.random(to: Int(UIScreen.main.bounds.width)), y: -30)
        case .up:
            virusP = CGPoint(x: Int.random(to: Int(UIScreen.main.bounds.width)), y: Int(UIScreen.main.bounds.height)+30)
        case .left:
            virusP = CGPoint(x: -30, y: Int.random(to: Int(UIScreen.main.bounds.height)))
        case .right:
            virusP = CGPoint(x: Int(UIScreen.main.bounds.width)+30, y: Int.random(to: Int(UIScreen.main.bounds.height)))
        default:
            break
        }
        return virusP
    }
}


// MARK: - Manager的协议
protocol GameManagerDelegate {
    func addToView(node: SKNode)
    func allVirusDied() -> Bool
}


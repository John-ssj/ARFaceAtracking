//
//  VirusExtensions.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/22.
//

import UIKit

enum VirusNames: String, CaseIterable {
    case yellowTail = "virus1"
    case greenBigEye = "virus2"
    case greenBomb = "virus3"
    case greenFatParents = "virus4"
    case redBigEye = "virus5"
    case colorfulBeauty = "virus6"
    case purpleQueen = "virus7"
    case greenKing = "virus8"
    case normalVirus = "virus9"
    
    var score: Int {
        switch self {
        case .yellowTail: return 1
        case .greenBigEye: return 5
        case .greenBomb: return 4
        case .greenFatParents: return 6
        case .redBigEye: return 7
        case .colorfulBeauty: return 3
        case .purpleQueen: return 10
        case .greenKing: return 12
        case .normalVirus: return 1
        }
    }
    
    var bitmask: UInt32 {
        switch self {
        case .yellowTail: return 1<<1
        case .greenBigEye: return 1<<2
        case .greenBomb: return 1<<3
        case .greenFatParents: return 1<<4
        case .redBigEye: return 1<<5
        case .colorfulBeauty: return 1<<6
        case .purpleQueen: return 1<<7
        case .greenKing: return 1<<8
        case .normalVirus: return 1<<9
        }
    }
}

enum ResultType: Int, CaseIterable {
    case unkonw = 0
    case left = 1
    case right = 2
    case up = 3
    case down = 4
    case v = 5
    case n = 6
    case circle = 7
    
    init(stringValue str: String){
        switch str {
        case "?": self = .unkonw
        case "←": self = .left
        case "→": self = .right
        case "↑": self = .up
        case "↓": self = .down
        case "〇": self = .circle
        case "v": self = .v
        case "ʌ": self = .n
        default: self = .unkonw
        }
    }
    
    var stringValue: String {
        switch self {
        case .unkonw: return "?"
        case .left: return "←"
        case .right: return "→"
        case .up: return "↑"
        case .down: return "↓"
        case .circle: return "〇"
        case .v: return "v"
        case .n: return "ʌ"
        }
    }
    
    var color: UIColor {
        switch self {
        case .unkonw: return #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        case .left: return #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        case .right: return #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
        case .up: return #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1)
        case .down: return #colorLiteral(red: 0.9995340705, green: 0.988355577, blue: 0.4726552367, alpha: 1)
        case .circle: return #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 1)
        case .v: return #colorLiteral(red: 0.476841867, green: 0.5048075914, blue: 1, alpha: 1)
        case .n: return #colorLiteral(red: 1, green: 0.5409764051, blue: 0.8473142982, alpha: 1)
        }
    }
    
    static let easyTypes = ["←", "→", "↑", "↓"]
    static let allVirusTypes = ["←", "→", "↑", "↓", "v", "ʌ"]
}

extension Int {
    static func random(from start: Int = 0, to end: Int) -> Int {
        return Int(arc4random()) % (end-start+1) + start
    }
}

extension String {
    subscript (i: Int) -> String {
        return "\(self[index(startIndex, offsetBy: i)])"
    }
}


extension CGPoint {
    static func -(left: CGPoint, right: CGPoint) -> CGPoint {
        var point = CGPoint()
        point.x = left.x - right.x
        point.y = left.y - right.y
        return point
    }
}


extension UIImage {
    static func virusImage(name virusName : VirusNames) -> UIImage {
        let path = Bundle.main.path(forResource: virusName.rawValue, ofType: "gif", inDirectory: "gif")!
        let url = URL(fileURLWithPath: path)
        let gifData = try? Data(contentsOf: url)
        let source =  CGImageSourceCreateWithData(gifData! as CFData, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 1, nil)!
        return UIImage(cgImage: image)
    }
}

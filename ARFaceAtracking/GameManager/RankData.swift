//
//  RankData.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/3/1.
//

import Foundation

class RankData {
    static let Rank2: [Int: [VirusNames: Int]] = [
        2: [.normalVirus: 4],
        5: [.colorfulBeauty: 2],
        10: [.yellowTail: 4],
        15: [.normalVirus: 4, .greenBigEye: 2],
        20: [.normalVirus: 4, .greenFatParents: 1],
        25: [.normalVirus: 1],
        30: [.normalVirus: 4, .greenBomb: 5, .colorfulBeauty: 1],
        35: [.normalVirus: 1],
        40: [.normalVirus: 4, .greenBomb: 1, .redBigEye: 1, .greenBigEye: 1],
        45: [.purpleQueen: 1],
        50: [.yellowTail: 4],
        55: [.normalVirus: 4, .greenBomb: 5, .colorfulBeauty: 1],
        60: [.normalVirus: 1],
        65: [.normalVirus: 4, .greenBomb: 1, .redBigEye: 1, .greenFatParents: 1],
        70: [.normalVirus: 4, .greenBomb: 2],
        75: [.greenKing: 1]
    ]
    
    static let Rank3: [Int: [VirusNames: Int]] = [
        2: [.normalVirus: 4],
        5: [.yellowTail: 2],
        10: [.yellowTail: 4],
        15: [.normalVirus: 4, .greenBigEye: 2],
        20: [.normalVirus: 4, .greenFatParents: 1],
        25: [.normalVirus: 1],
        30: [.normalVirus: 4, .greenBomb: 5, .yellowTail: 1],
        35: [.normalVirus: 1],
        40: [.normalVirus: 4, .greenBomb: 1, .redBigEye: 1, .greenBigEye: 1],
        45: [.purpleQueen: 1],
        50: [.yellowTail: 4],
        55: [.normalVirus: 4, .greenBomb: 5, .yellowTail: 1],
        60: [.normalVirus: 1],
        65: [.normalVirus: 4, .greenBomb: 1, .redBigEye: 1, .greenFatParents: 1],
        70: [.normalVirus: 4, .greenBomb: 2],
        75: [.greenKing: 1]
    ]
    
    static let Rank1: [Int: [VirusNames: Int]] = {
        var rank = [Int: [VirusNames: Int]]()
        for i in 1..<6000 {
            var virusDic = [VirusNames: Int]()
            virusDic[.normalVirus] = createNormal(i)
            virusDic[.yellowTail] = createYellowTail(i)
            virusDic[.greenBigEye] = createGreenBigEye(i)
            virusDic[.greenBomb] = createGreenBomb(i)
            virusDic[.greenFatParents] = createFatParents(i)
            virusDic[.redBigEye] = createRedBigEye(i)
            virusDic[.colorfulBeauty] = createColorfulBeauty(i)
            virusDic[.purpleQueen] = createPurpleQueen(i)
            virusDic[.greenKing] = createGreenKing(i)
            rank[i*5] = virusDic
        }
        return rank
    }()
    
    /*
     case yellowTail = "virus1"
     case greenBigEye = "virus2"
     case greenBomb = "virus3"
     case greenFatParents = "virus4"
     case redBigEye = "virus5"
     case colorfulBeauty = "virus6"
     case purpleQueen = "virus7"
     case greenKing = "virus8"
     case normalVirus = "virus9"
     */
    static private func createNormal(_ i: Int) -> Int {
        //开局15s都有Normal
        if i<=5 { return Int.random(from: 1, to: 4) }
        // 其它时候永远1/3概率生成
        guard Int.random(to: 2) == 0 else { return 0 }
        let max = i<60 ? 3 : (i<180 ? 6 : 9)
        return Int.random(from: 1, to: max)
    }
    
    static private func createYellowTail(_ i: Int) -> Int {
        //开局6s,12s有YellowTail
        if i==2 || i==4 { return Int.random(from: 1, to: 4) }
        // 永远1/10概率生成
        guard Int.random(to: 9) == 0 else { return 0 }
        let max = i<30 ? 2 : (i<60 ? 6 : 12)
        return Int.random(from: 2, to: max)
    }
    
    static private func createGreenBigEye(_ i: Int) -> Int {
        //开局15s有GreenBigEye
        if i==5 { return 3 }
        // 永远1/7概率生成
        guard i%24 < 17 else { return 0 }
        guard Int.random(to: 6) == 0 else { return 0 }
        let max = i<30 ? 2 : (i<60 ? 3 : 5)
        return Int.random(from: 1, to: max)
    }
    
    static private func createGreenBomb(_ i: Int) -> Int {
        //开局15s有GreenBomb
        if i==5 { return Int.random(from: 2, to: 4) }
        //每分钟15s有大量GreenBomb
        if i%12 == 5 {
            return Int.random(from: i<80 ? 3 : (i<200 ? 4 : 5),
                              to: i<80 ? 10 : (i<200 ? 14 : 18))
        }
        // 永远1/8概率生成
        guard Int.random(to: 7) == 0 else { return 0 }
        let max = i<30 ? 2 : (i<60 ? 3 : 5)
        return Int.random(from: 1, to: max)
    }
    
    static private func createFatParents(_ i: Int) -> Int {
        //开局21s有FatParents
        if i==7 { return Int.random(from: 2, to: 4) }
        //每分钟21s有大量FatParents
        if i%12 == 7 {
            return Int.random(from: i<800 ? 1 : 2,
                              to: i<180 ? 1 : (i<800 ? 3 : 5))
        }
        // 永远1/10概率生成
        guard i%24 < 17 else { return 0 }
        guard Int.random(to: 9) == 0 else { return 0 }
        let max = i<60 ? 1 : (i<180 ? 2 : 3)
        return Int.random(from: 1, to: max)
    }
    
    static private func createRedBigEye(_ i: Int) -> Int {
        //开局42s有RedBigEye
        if i==14 { return 1 }
        //每分钟42s有RedBigEye
        if i%12 == 14 {
            return Int.random(from: i<400 ? 1 : 2,
                              to: i<200 ? 1 : (i<400 ? 2 : 3))
        }
        guard i%24 < 17 else { return 0 }
        // 永远1/24概率生成
        guard Int.random(to: 23) == 0 else { return 0 }
        let max = i<180 ? 1 : (i<800 ? 2 : 3)
        return Int.random(from: 1, to: max)
    }
    
    static private func createColorfulBeauty(_ i: Int) -> Int {
        //开局30s有ColorfulBeauty
        if i==10 { return 2 }
        // 1/12 -> 1/8 概率生成
        guard i%24 < 17 else { return 0 }
        guard Int.random(to: i<180 ? 11 : 7) == 0 else { return 0 }
        let max = i<180 ? 1 : i<400 ? 2 : 3
        return Int.random(from: 1, to: max)
    }
    
    static private func createPurpleQueen(_ i: Int) -> Int {
        // 1/24 -> 1/18概率生成
        guard Int.random(to: i<200 ? 23 : 17) == 0 else { return 0 }
        return 1
    }
    
    static private func createGreenKing(_ i: Int) -> Int {
        //每两分钟51s有GreenKing
        if i%24 == 17 { return 1 }
        return 0
    }
}

//
//  VirusNode.swift
//  ARFaceAtracking
//
//  Created by 史导的Mac on 2021/4/5.
//

import SpriteKit

class VirusNode: SymbolNode {
    
    private var virusNames: VirusNames!
    private var info: VirusInfo!
    
    convenience init(name: VirusNames, dir: CGVector? = nil) {
        let moveMode: MovingMode = (dir == nil) ? .toPoint : .toDir
        self.init(move: moveMode, changeM: true)
        if dir != nil { self.movingDir = dir }
        
        setUpVirus(name)
    }
    
    private func setUpVirus(_ name: VirusNames) {
        self.virusNames = name
        self.info = VirusInfo.All[name]
        if self.info.animated {
            self.setUpGif(with: VirusNode.gifResource[name]!, frameTime: self.info.frameDuration, size: self.info.size)
        }else {
            self.setUpPng(with: VirusNode.pngResource.randomElement()!, size: self.info.size)
        }
        
    }
    
    override func nodeDisappear() {
        
    }
    
}

//MARK: - 加载 gif/png 资源
extension VirusNode {
    
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
        print("load gif Success!")
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
        print("load png Success!")
        return dic
    }()
}


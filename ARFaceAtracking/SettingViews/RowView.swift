//
//  RowView.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/3/1.
//

import UIKit

class RowView: UIView {
    var time = 0 {
        didSet{ self.timeLabel.text = "\(time)" }
    }
    var virusList: [VirusNames] = []
    private var scoreView = UIScrollView()
    private var virusSize = CGSize(width: 80, height: 80)
    private var timeLabel = UILabel()
    
    convenience init(time: Int) {
        self.init()
        self.backgroundColor = UIColor.clear
        self.time = time
        self.bounds = CGRect(x: 0, y: 0, width: 800, height: 100)
        self.layer.masksToBounds = true
        
        timeLabel.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        timeLabel.frame = CGRect(x: 0, y: 10, width: 55, height: 80)
        timeLabel.text = "\(time)"
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        self.addSubview(timeLabel)
        timeLabel.layer.cornerRadius = 3
        timeLabel.layer.masksToBounds = true
        
        scoreView.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        scoreView.tag = 20
        scoreView.frame = CGRect(x: 50, y: 0, width: 750, height: 100)
        self.addSubview(scoreView)
        scoreView.layer.cornerRadius = 20
        scoreView.layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func insertVirus(name: VirusNames) {
        let virusView = UIImageView(frame: CGRect(x: CGFloat(virusList.count) * self.virusSize.width + 10, y: 10, width: 80, height: 80))
        virusView.tag = 30
        virusView.image = UIImage.virusImage(name: name)
        self.scoreView.addSubview(virusView)
        virusList.append(name)
        let newWidth = CGFloat(virusList.count) * self.virusSize.width + 20
        if self.scoreView.contentSize.width < newWidth {
            self.scoreView.contentSize.width = newWidth
        }
    }
    
    func getVirusList() -> [VirusNames: Int] {
        var list: [VirusNames: Int] = [:]
        for virus in virusList {
            list[virus, default: 0] += 1;
        }
        return list
    }
}

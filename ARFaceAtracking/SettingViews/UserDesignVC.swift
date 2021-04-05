//
//  UserDesignVC.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/3/1.
//

import UIKit

class UserDesignVC: UIViewController {
    
    var finishButton = UIButton()
    var scoreView = UIScrollView()
    var rowViews: [RowView] = []
    var movingImageView: UIImageView?
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.white
        
        view.addSubview(finishButton)
        finishButton.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        finishButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            finishButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            finishButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            finishButton.widthAnchor.constraint(equalToConstant: 100),
            finishButton.heightAnchor.constraint(equalToConstant: 100)
        ])
        finishButton.layer.cornerRadius = 10
        finishButton.layer.masksToBounds = true
        finishButton.setTitle("Start!", for: .normal)
        finishButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        finishButton.addTarget(self, action: #selector(finishEditing), for: .touchDown)
        
        for i in 1...8 {
            let image = UIImage.virusImage(name: VirusNames(rawValue: "virus\(i)")!)
            let imageView = UIImageView(image: image)
            imageView.isUserInteractionEnabled = true
            imageView.backgroundColor = UIColor.yellow
            imageView.tag = i
            imageView.frame = CGRect(x: 100*i+100, y: 20, width: 80, height: 80)
            imageView.layer.cornerRadius = 10
            imageView.layer.masksToBounds = true
            view.addSubview(imageView)
        }
        
        
        view.addSubview(scoreView)
        scoreView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreView.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            scoreView.widthAnchor.constraint(equalToConstant: 1000),
            scoreView.heightAnchor.constraint(equalToConstant: 500)
        ])
        scoreView.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        for i in 1...6 {
            let rowView = RowView(time: i*5)
            rowView.frame = CGRect(x: 100, y: 20 + 120 * rowViews.count, width: 800, height: 100)
            scoreView.addSubview(rowView)
            self.rowViews.append(rowView)
            if scoreView.contentSize.height <= 120 * CGFloat(rowViews.count) {
                scoreView.contentSize.height += 120
            }
        }
        scoreView.layer.cornerRadius = 20
        scoreView.layer.masksToBounds = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1, let touchView = touches.first?.view else { return }
        if touchView.tag <= 8 {
            guard let imageView = touchView as? UIImageView,
                  let image = imageView.image else { return }
            movingImageView = UIImageView(image: image)
            movingImageView?.tag = imageView.tag
            movingImageView?.frame = imageView.frame
            view.addSubview(movingImageView!)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else { return }
        if let imageView = movingImageView, let point = touches.first?.location(in: view) {
            UIView.animate(withDuration: 0.1) {
                let originPoint = CGPoint(x: point.x - imageView.bounds.size.width/2, y: point.y - imageView.bounds.size.height/2)
                imageView.frame = CGRect(origin: originPoint, size: imageView.bounds.size)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else { return }
        let point = touches.first!.location(in: view)
        if let imageView = movingImageView,
           view.hitTest(point, with: nil)?.tag == 20,
           let rowView = view.hitTest(point, with: nil)?.superview as? RowView{
            let name = VirusNames(rawValue: "virus\(imageView.tag)")!
            rowView.insertVirus(name: name)
        }
        movingImageView?.removeFromSuperview()
        movingImageView = nil
    }
    
    func getAllVirusDic() -> [Int: [VirusNames: Int]] {
        var virusDic: [Int: [VirusNames: Int]] = [:]
        for rowView in rowViews {
            let virus = rowView.getVirusList()
            if virus.count == 0 { continue }
            virusDic[rowView.time] = virus
        }
        return virusDic
    }
    
    @objc private func finishEditing() {
        let dic = getAllVirusDic()
        guard dic.count>0 else {
            GameAudio.share.backGroundAudio(audio: .error)
            return
        }
        GameCenter.shared.setVirusDic(dic)
        NotificationCenter.default.post(Notification(name: Notification.Name("StartGame")))
        self.dismiss(animated: true)
    }
}

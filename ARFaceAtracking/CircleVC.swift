//
//  CircleVC.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/15.
//

import UIKit

class CircleVC: UIViewController {
    
    lazy var gestureView = GestureDrawView(frame: self.view.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        
        view.addSubview(gestureView)
        
        let gameGesture = GameGestureRecognizer(target: self, action: #selector(GestureRespondent))
        view.addGestureRecognizer(gameGesture)
    }
    
    
    @objc func GestureRespondent(sender: GameGestureRecognizer) {
        gestureView.updatePath(p: sender.path, color: sender.result.color)
        if sender.state == .ended {
            gestureView.showResult(type: sender.result)
            switch sender.result {
            case .v:
                print("v")
            case .n:
                print("n")
            case .circle:
                print("circle")
            case .up:
                print("up")
            case .down:
                print("down")
            case .left:
                print("left")
            case .right:
                print("right")
            default:
                print("unknow")
            }
        }
    }
}

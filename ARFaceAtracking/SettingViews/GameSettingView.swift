//
//  GameSettingView.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/23.
//

import UIKit

class GameSettingView: UIView {
    
    var viewDelegate: SettingViewDelegate?
    private var settingView = UIView()
    private var closeButton = UIButton()
    private var historyView = UILabel()
    private var DesignButton = UIButton()
    private var restartButton = UIButton()
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
        self.isHidden = true
        self.backgroundColor = UIColor.clear
        
        setUpView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpView() {
        
        self.addSubview(settingView)
        settingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            settingView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            settingView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            settingView.widthAnchor.constraint(equalToConstant: 700),
            settingView.heightAnchor.constraint(equalToConstant: 550)
        ])
        self.settingView.layer.cornerRadius = 30
        self.settingView.backgroundColor = UIColor.white
        
        settingView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 60),
            closeButton.topAnchor.constraint(equalTo: self.settingView.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: self.settingView.trailingAnchor, constant: -20)
        ])
        closeButton.backgroundColor = UIColor.red
        closeButton.layer.cornerRadius = 30
        closeButton.layer.masksToBounds = true
        closeButton.setImage(UIImage(systemName: "xmark")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: .normal)
        closeButton.addTarget(self, action: #selector(closeSelf), for: .touchDown)
        
        settingView.addSubview(historyView)
        historyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            historyView.leadingAnchor.constraint(equalTo: settingView.leadingAnchor, constant: 80),
            historyView.trailingAnchor.constraint(equalTo: settingView.trailingAnchor, constant: -80),
            historyView.topAnchor.constraint(equalTo: settingView.topAnchor, constant: 40),
            historyView.bottomAnchor.constraint(equalTo: settingView.bottomAnchor, constant: -220)
        ])
        historyView.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
        historyView.layer.cornerRadius = 30
        historyView.layer.masksToBounds = true
        historyView.textAlignment = .center
        historyView.textColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        historyView.font = UIFont.systemFont(ofSize: 100, weight: .bold)
        
        settingView.addSubview(restartButton)
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            restartButton.widthAnchor.constraint(equalToConstant: 160),
            restartButton.heightAnchor.constraint(equalToConstant: 160),
            restartButton.bottomAnchor.constraint(equalTo: self.settingView.bottomAnchor, constant: -50),
            restartButton.centerXAnchor.constraint(equalTo: self.settingView.centerXAnchor, constant: -80-30)
        ])
        restartButton.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        restartButton.layer.cornerRadius = 30
        restartButton.layer.masksToBounds = true
        restartButton.setImage(UIImage(systemName: "goforward")?.withRenderingMode(.alwaysOriginal).withTintColor(.white), for: .normal)
        restartButton.addTarget(self, action: #selector(restartGame), for: .touchDown)
        
        settingView.addSubview(DesignButton)
        DesignButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            DesignButton.widthAnchor.constraint(equalToConstant: 160),
            DesignButton.heightAnchor.constraint(equalToConstant: 160),
            DesignButton.bottomAnchor.constraint(equalTo: self.settingView.bottomAnchor, constant: -50),
            DesignButton.centerXAnchor.constraint(equalTo: self.settingView.centerXAnchor, constant: 80+30)
        ])
        DesignButton.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        DesignButton.layer.cornerRadius = 30
        DesignButton.layer.masksToBounds = true
        DesignButton.setTitle("New Game!", for: .normal)
        DesignButton.addTarget(self, action: #selector(OpenDesignView), for: .touchDown)
    }
    
    func open() {
        self.isHidden = false
        if self.settingView.center.y != self.center.y - UIScreen.main.bounds.height {
            self.settingView.center.y -= UIScreen.main.bounds.height
        }
        //更新记录
        historyView.text = "highest:\(GameCenter.shared.getHistoryScore())!"
        //如果是end状态，不能直接关闭settingView
        self.closeButton.isHidden = (GameCenter.shared.gameState == .end)
        UIView.animate(withDuration: 1.8, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 5) {
            self.settingView.center.y += UIScreen.main.bounds.height
        }
    }
    
    @objc private func closeSelf() {
        UIView.animate(withDuration: 0.8) {
            self.settingView.center.y -= UIScreen.main.bounds.height
        } completion: { _ in
            self.isHidden = true
        }
        
        self.viewDelegate?.settingViewClose()
    }
    
    @objc private func restartGame() {
        UIView.animate(withDuration: 0.8) {
            self.settingView.center.y -= UIScreen.main.bounds.height
        } completion: { _ in
            self.isHidden = true
        }
        
        self.viewDelegate?.restartGame()
    }
    
    @objc private func OpenDesignView() {
        self.settingView.center.y -= UIScreen.main.bounds.height
        self.isHidden = true
        
        NotificationCenter.default.post(Notification(name: Notification.Name("OpenDesignView")))
    }
}

protocol SettingViewDelegate {
    func settingViewClose()
    func restartGame()
}

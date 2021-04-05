//
//  ViewController.swift
//  ARFaceAtracking
//
//  Created by apple on 2021/2/9.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {

    let sVM = GazeTrackingManager()
    lazy var sceneView = sVM.arView()
    var labelView = UIView()
    var faceLabel = UILabel()
    var drawPointDelegate = DrawPointDelegate()
    lazy var pointLayer: CALayer = {
        let layer = CALayer()
        layer.delegate = drawPointDelegate
        layer.frame = view.bounds
        return layer
    }()
    
    var analysis = 0 {
        didSet{
            DispatchQueue.main.async {
                self.faceLabel.text = String(self.analysis)
            }
        }
    }
    var eyeIsOpened = true
    var lookPoint = CGPoint.zero {
        didSet{
            drawPointDelegate.point = self.lookPoint
            pointLayer.setNeedsDisplay()
            self.faceLabel.text! = "\(self.lookPoint)"
        }
    }
    
    func ha(_ x:Int,_ y:Int) {
        self.lookPoint = CGPoint(x: x, y: y)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sVM.updateHandler = ha(_:_:)

        sceneView.frame = view.bounds
        view.addSubview(sceneView)

        pointLayer.backgroundColor = UIColor.white.cgColor
        pointLayer.opacity = 0.8
        view.layer.addSublayer(pointLayer)

        labelView.frame = CGRect(x: 20, y: 100, width: 400, height: 80)
        labelView.backgroundColor = UIColor.white
        view.addSubview(labelView)

        faceLabel.frame = labelView.bounds.insetBy(dx: 10, dy: 10)
        faceLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        faceLabel.numberOfLines = 0
        faceLabel.textColor = UIColor.red
        labelView.addSubview(faceLabel)

        labelView.layer.cornerRadius = 10
        labelView.layer.masksToBounds = true
        self.analysis = 0

        let guseture1 = UISwipeGestureRecognizer(target: self, action: #selector(jumpToNextView1))
        guseture1.direction = .up
        view.addGestureRecognizer(guseture1)

        let guseture2 = UISwipeGestureRecognizer(target: self, action: #selector(jumpToNextView2))
        guseture2.direction = .left
        view.addGestureRecognizer(guseture2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        jumpToNextView2()
    }
    
    
    @objc func jumpToNextView1() {
        let nextView = UserDesignVC()
//            CircleVC()
        nextView.modalPresentationStyle = .fullScreen
        self.present(nextView, animated: true, completion: nil)
    }
    
    @objc func jumpToNextView2() {
        let nextView = GameViewController()
        nextView.modalPresentationStyle = .fullScreen
        self.present(nextView, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        let configuration = ARFaceTrackingConfiguration()
//        sceneView.session.run(configuration)
        sVM.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        sceneView.session.pause()
        sVM.pause()
    }
    
    
    // MARK:- ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        node.geometry?.firstMaterial?.fillMode = .lines
        return node
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor)
            
            print(faceAnchor.lookAtPoint)
            
            DispatchQueue.main.async {
                self.lookPoint = self.sceneView.session.currentFrame?.camera.projectPoint(faceAnchor.lookAtPoint, orientation: .portrait, viewportSize: self.view.bounds.size) ?? CGPoint.zero
            }
        }
    }
    
    func expression(anchor: ARFaceAnchor) {
        let eyeBlinkLeft = anchor.blendShapes[.eyeBlinkLeft]
        let eyeBlinkRight = anchor.blendShapes[.eyeBlinkRight]
        let eyeBlinkValue = (eyeBlinkLeft?.decimalValue ?? 0.0) + (eyeBlinkRight?.decimalValue ?? 0.0)
        
        if eyeIsOpened && eyeBlinkValue > 1.5 {
            self.analysis += 1
            eyeIsOpened = false
        } else if !eyeIsOpened && eyeBlinkValue < 0.5 {
            eyeIsOpened = true
        }
    }
}

class DrawPointDelegate: NSObject, CALayerDelegate {
    var point = CGPoint.zero
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        
        ctx.setStrokeColor(UIColor.red.cgColor)
        ctx.setLineWidth(1)
        ctx.strokeEllipse(in: CGRect(origin: point, size: CGSize(width: 3, height: 3)))
    }
}


class GazeTrackingManager:NSObject {

    var updateHandler:((_ x:Int,_ y:Int)->Void)?

    var lookAtPositionX = 0
    var lookAtPositionY = 0

    var faceNode = SCNNode()
    
    var leftEyeNode = SCNNode()
    
    var rightEyeNode = SCNNode()
    
    var lookAtTargetLeftEyeNode = SCNNode()
    var lookAtTargetRightEyeNode = SCNNode()
    
    // iPhone X 的屏幕实际尺寸（单位：米）
    let phoneScreenMeterSize = CGSize(width: 0.0774, height: 0.1575)
    
    // iPhone X 尺寸（单位：点）
    let phoneScreenPointSize = UIScreen.main.bounds.size
    
    var virtualPhoneNode = SCNNode()
    
    var virtualScreenNode = SCNNode(geometry: SCNPlane(width: 1, height: 1))
    
    private var sceneView: ARSCNView!
    
    private var eyeLookAtPositionXs: [CGFloat] = []
    
    private var eyeLookAtPositionYs: [CGFloat] = []
    
    func arView() -> ARSCNView {
        sceneView = ARSCNView()
//        sceneView.isHidden = true
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // 增加面部、眼睛、手机节点及参考节点
        sceneView.scene.rootNode.addChildNode(faceNode)
        sceneView.scene.rootNode.addChildNode(virtualPhoneNode)
        virtualPhoneNode.addChildNode(virtualScreenNode)
        faceNode.addChildNode(leftEyeNode)
        faceNode.addChildNode(rightEyeNode)
        leftEyeNode.addChildNode(lookAtTargetLeftEyeNode)
        rightEyeNode.addChildNode(lookAtTargetRightEyeNode)

        // 设置两个子节点作为参考点
        lookAtTargetLeftEyeNode.position.z = 2
        lookAtTargetRightEyeNode.position.z = 2

        return sceneView
    }

    func start() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func pause() {
        sceneView.session.pause()
    }

    private func update(withFaceAnchor anchor: ARFaceAnchor) {
        rightEyeNode.simdTransform = anchor.rightEyeTransform
        leftEyeNode.simdTransform = anchor.leftEyeTransform

        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        DispatchQueue.main.async {
            
            // 进行两个节点和虚拟手机之间的碰撞检测以确定焦点在手机上的位置
            let phoneScreenEyeRHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetRightEyeNode.worldPosition, to: self.rightEyeNode.worldPosition, options: nil)

            let phoneScreenEyeLHitTestResults = self.virtualPhoneNode.hitTestWithSegment(from: self.lookAtTargetLeftEyeNode.worldPosition, to: self.leftEyeNode.worldPosition, options: nil)

            for result in phoneScreenEyeRHitTestResults {
                eyeRLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenMeterSize.width / 2) * self.phoneScreenPointSize.width

                eyeRLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenMeterSize.height / 2) * self.phoneScreenPointSize.height
            }

            for result in phoneScreenEyeLHitTestResults {
                eyeLLookAt.x = CGFloat(result.localCoordinates.x) / (self.phoneScreenMeterSize.width / 2) * self.phoneScreenPointSize.width

                eyeLLookAt.y = CGFloat(result.localCoordinates.y) / (self.phoneScreenMeterSize.height / 2) * self.phoneScreenPointSize.height
            }

            // 取最近的几次j位置以确保不会漂移
            let smoothThresholdNumber: Int = 10
            self.eyeLookAtPositionXs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
            self.eyeLookAtPositionYs.append(-(eyeRLookAt.y + eyeLLookAt.y) / 2)
            self.eyeLookAtPositionXs = Array(self.eyeLookAtPositionXs.suffix(smoothThresholdNumber))
            self.eyeLookAtPositionYs = Array(self.eyeLookAtPositionYs.suffix(smoothThresholdNumber))

            // 求平均
            let smoothEyeLookAtPositionX = self.eyeLookAtPositionXs.map{ $0/CGFloat(self.eyeLookAtPositionXs.count) }.reduce(0, +)
            let smoothEyeLookAtPositionY = self.eyeLookAtPositionYs.map{ $0/CGFloat(self.eyeLookAtPositionYs.count) }.reduce(0, +)

            self.lookAtPositionX = Int(round(smoothEyeLookAtPositionX + self.phoneScreenPointSize.width / 2))

            self.lookAtPositionY = Int(round(smoothEyeLookAtPositionY + self.phoneScreenPointSize.height / 2))

            self.updateHandler?(self.lookAtPositionX,self.lookAtPositionY)
        }
    }
}

extension GazeTrackingManager:ARSessionDelegate, ARSCNViewDelegate {
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(withFaceAnchor: faceAnchor)
    }

    // MARK - ARSessionDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        virtualPhoneNode.transform = (sceneView.pointOfView?.transform)!
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        let eyeBlinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft]
        let eyeBlinkRight = faceAnchor.blendShapes[.eyeBlinkRight]
        let eyeBlinkValue = (eyeBlinkLeft?.decimalValue ?? 0.0) + (eyeBlinkRight?.decimalValue ?? 0.0)
        if eyeBlinkValue < 0.5 {
            update(withFaceAnchor: faceAnchor)
        }
    }
}

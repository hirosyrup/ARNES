//
//  GameViewController.swift
//  ARNES
//
//  Created by 岩井 宏晃 on 2019/05/20.
//  Copyright © 2019 koalab. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class GameViewController: UIViewController, ARSCNViewDelegate, EmulatorDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    private let nesNode = SCNNode()
    private let emulator = Emulator()
    private var nesGeometry = NesGeometory()
    private var planeGeometryNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        
        emulator.delegate = self
        
        startRunning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func startRunning() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.session = sceneView.session
        coachingOverlay.frame = sceneView.bounds
        sceneView.addSubview(coachingOverlay)
    }
    
    private func addNesNode(hitTestPosition: SCNVector3) {
        sceneView.scene.rootNode.addChildNode(nesNode)
        nesNode.position = SCNVector3(x: hitTestPosition.x, y: hitTestPosition.y + 0.5, z: hitTestPosition.z)
        if let camera = sceneView.pointOfView {
            let eulerAngles = camera.eulerAngles
            nesNode.eulerAngles = SCNVector3(0.0, eulerAngles.y, 0.0)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeGeoemtry = ARSCNPlaneGeometry(device: sceneView.device!) else { fatalError() }
        if planeGeometryNode == nil {
            planeGeoemtry.materials.first!.diffuse.contents = UIColor.clear
            planeGeometryNode = SCNNode(geometry: planeGeoemtry)
            node.addChildNode(planeGeometryNode!)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard let planeGeometry = node.childNodes.filter({$0.geometry is ARSCNPlaneGeometry}).first?.geometry as? ARSCNPlaneGeometry else { return }
        planeGeometry.update(from: planeAnchor.geometry)
    }
    
    func updateBuffer(_ buffer: UnsafeMutablePointer<UInt32>!, width: Int, height: Int) {
        DispatchQueue.main.async {
            self.nesNode.geometry = self.nesGeometry.createGeometory(buffer, width: width, height: height)
        }
    }
    
    @IBAction func pushShow(_ sender: UIButton) {
        let results = sceneView.hitTest(view.center, types: .existingPlaneUsingGeometry)
        if let result = results.first {
            let transform = result.worldTransform.columns.3
            addNesNode(hitTestPosition: SCNVector3(transform.x, transform.y, transform.z))
            emulator.start()
        }
    }
    
    @IBAction func pushBgButton(_ sender: Any) {
        nesGeometry.showBg = !nesGeometry.showBg
    }
    
    @IBAction func pushButton(_ sender: UIButton) {
        let player = 0
        switch sender.tag {
        case 0:
            emulator.pushButton(buttonType: .left, forPlayer: player)
            emulator.pushButton(buttonType: .up, forPlayer: player)
        case 1:
            emulator.pushButton(buttonType: .up, forPlayer: player)
        case 2:
            emulator.pushButton(buttonType: .up, forPlayer: player)
            emulator.pushButton(buttonType: .right, forPlayer: player)
        case 3:
            emulator.pushButton(buttonType: .right, forPlayer: player)
        case 4:
            emulator.pushButton(buttonType: .right, forPlayer: player)
            emulator.pushButton(buttonType: .down, forPlayer: player)
        case 5:
            emulator.pushButton(buttonType: .down, forPlayer: player)
        case 6:
            emulator.pushButton(buttonType: .down, forPlayer: player)
            emulator.pushButton(buttonType: .left, forPlayer: player)
        case 7:
            emulator.pushButton(buttonType: .left, forPlayer: player)
        case 8:
            emulator.pushButton(buttonType: .select, forPlayer: player)
        case 9:
            emulator.pushButton(buttonType: .start, forPlayer: player)
        case 10:
            emulator.pushButton(buttonType: .B, forPlayer: player)
        case 11:
            emulator.pushButton(buttonType: .A, forPlayer: player)
        default:
            return
        }
    }
    
    @IBAction func releaseButton(_ sender: UIButton) {
        let player = 0
        switch sender.tag {
        case 0:
            emulator.releaseButton(buttonType: .left, forPlayer: player)
            emulator.releaseButton(buttonType: .up, forPlayer: player)
        case 1:
            emulator.releaseButton(buttonType: .up, forPlayer: player)
        case 2:
            emulator.releaseButton(buttonType: .up, forPlayer: player)
            emulator.releaseButton(buttonType: .right, forPlayer: player)
        case 3:
            emulator.releaseButton(buttonType: .right, forPlayer: player)
        case 4:
            emulator.releaseButton(buttonType: .right, forPlayer: player)
            emulator.releaseButton(buttonType: .down, forPlayer: player)
        case 5:
            emulator.releaseButton(buttonType: .down, forPlayer: player)
        case 6:
            emulator.releaseButton(buttonType: .down, forPlayer: player)
            emulator.releaseButton(buttonType: .left, forPlayer: player)
        case 7:
            emulator.releaseButton(buttonType: .left, forPlayer: player)
        case 8:
            emulator.releaseButton(buttonType: .select, forPlayer: player)
        case 9:
            emulator.releaseButton(buttonType: .start, forPlayer: player)
        case 10:
            emulator.releaseButton(buttonType: .B, forPlayer: player)
        case 11:
            emulator.releaseButton(buttonType: .A, forPlayer: player)
        default:
            return
        }
    }
}

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

class GameViewController: UIViewController, ARSCNViewDelegate, NesGeometoryDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    private let nesNode = SCNNode()
    private var nesGeometry = NesGeometory()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        
        nesGeometry.delegate = self
        nesNode.scale = SCNVector3(x: 0.005, y: 0.005, z: 0.05)
        nesNode.position = SCNVector3(x: 0, y: 1.0, z: -1.0)
        
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
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !node.childNodes.contains(nesNode) {
            node.addChildNode(nesNode)
            nesGeometry.start()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        nesNode.removeFromParentNode()
        nesGeometry.pause()
    }
    
    func updateGeometory(geometory: SCNGeometry) {
        nesNode.geometry = geometory
    }
}

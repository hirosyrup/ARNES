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
    private var stableCount = 0
    private var stableAnchorNodePosition = SCNVector3Zero
    private var stableAnchorNodeAngles = SCNVector3Zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        
        nesGeometry.delegate = self
        
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
    
    private func addNodes(parentNode: SCNNode) {
        parentNode.addChildNode(nesNode)
        nesNode.position = SCNVector3(x: -1.0, y: 0.6, z: -0.7)
        let eulerAngles = parentNode.eulerAngles
        nesNode.eulerAngles = SCNVector3(eulerAngles.x, -eulerAngles.y, eulerAngles.z)
    }
    
    private func retainAnchorNodePostionAndAngles(parentNode: SCNNode) {
        if !isStableAnchor() {
            let parentPosition = parentNode.position
            let parentAngles = parentNode.eulerAngles
            // positionに関してはyは微妙に暴れるので見ない。angleに関してはy以外変わらないのでyのみ比較
            if stableAnchorNodePosition.x == parentPosition.x &&
                stableAnchorNodePosition.z == parentPosition.z &&
                stableAnchorNodeAngles.y == parentAngles.y {
                stableCount += 1
            } else {
                stableCount = 0
            }
            stableAnchorNodePosition = parentPosition
            stableAnchorNodeAngles = parentAngles
        }
    }
    
    private func isStableAnchor() -> Bool {
        return stableCount >= 10
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        if isStableAnchor() {
            node.eulerAngles = stableAnchorNodeAngles
            DispatchQueue.main.async {
                if !node.childNodes.contains(self.nesNode) {
                    self.addNodes(parentNode: node)
                    self.nesGeometry.start()
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        self.retainAnchorNodePostionAndAngles(parentNode: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        nesNode.removeFromParentNode()
        nesGeometry.pause()
    }
    
    func updateGeometory(geometory: SCNGeometry) {
        nesNode.geometry = geometory
    }
    
    @IBAction func pushBgButton(_ sender: Any) {
        nesGeometry.showBg = !nesGeometry.showBg
    }
}

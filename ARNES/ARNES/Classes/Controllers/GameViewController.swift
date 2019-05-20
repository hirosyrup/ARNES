//
//  GameViewController.swift
//  ARNES
//
//  Created by 岩井 宏晃 on 2019/05/20.
//  Copyright © 2019 koalab. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

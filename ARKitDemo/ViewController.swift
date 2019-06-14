//
//  ViewController.swift
//  ARKitDemo
//
//  Created by mac on 6/14/19.
//  Copyright © 2019 UniCreo. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum PhysicsCategory:Int {
    case hero = 1
    case ground = 2
    case enemy = 4
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var plane: Plane!
    var hero: Hero!
    var enemy: Enemy!
    
    var scoreLabel: SCNText!
    var scoreNode: SCNNode!
    
    var gameOverLabel: SCNText!
    var gameOverNode: SCNNode!
    
    let planes: NSMutableDictionary! = [:]
    var configuration: ARWorldTrackingConfiguration! = nil
    var bPlaneAdded = false
    
    var bGameSetup = false
    var bGameOver = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        //        sceneView.scene = scene
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
                                  SCNDebugOptions.showPhysicsShapes]
        
//        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin,
//                                  ARSCNDebugOptions.showFeaturePoints,
//                                  SCNDebugOptions.showPhysicsShapes]
        
        sceneView.scene.physicsWorld.gravity = SCNVector3Make(0, -500/100.0, 0)
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection(rawValue: 1)
        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if(!anchor .isKind(of: ARPlaneAnchor.self)) { return }
        plane = Plane(anchor as! ARPlaneAnchor)
        planes.setObject(plane as Any, forKey: anchor.identifier as NSCopying)
        node.addChildNode(plane)
        bPlaneAdded = true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        plane = planes.object(forKey: anchor.identifier) as? Plane
        if(plane == nil){ return }
        plane.update(anchor as! ARPlaneAnchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node:SCNNode, for anchor: ARAnchor) {
        planes.removeObject(forKey: anchor.identifier )
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    private func setupGame(_ spawnPos: SCNVector3) {
        
        //Hero init
        hero = Hero(sceneView.scene, spawnPos)
        hero.castsShadow = true
        
        //Enemy itin
        enemy = Enemy(sceneView.scene, spawnPos)
        enemy.castsShadow = true
        
        
        //Light
        let directionLight = SCNLight()
        directionLight.type = SCNLight.LightType.directional
        directionLight.castsShadow = true
        directionLight.shadowRadius = 200
        directionLight.shadowColor = UIColor(red: 0,green: 0, blue: 0, alpha: 0.3)
        directionLight.shadowMode = .deferred
        
        let directionLightNode = SCNNode()
        directionLightNode.light = directionLight
        directionLightNode.transform =  SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0)
        directionLightNode.position = SCNVector3(spawnPos.x + 0.2, spawnPos.y + 0.5, spawnPos.z + 0.0)
        sceneView.scene.rootNode.addChildNode(directionLightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor.darkGray
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
        
        //Ground
        let ground = SCNFloor()
        ground.firstMaterial?.diffuse.contents = UIColor.gray
        ground.firstMaterial?.colorBufferWriteMask = .init(rawValue: 0)
        let groundNode = SCNNode(geometry: ground)
        groundNode.physicsBody = SCNPhysicsBody(type: .static, shape:SCNPhysicsShape(geometry: ground, options:nil))
        groundNode.position = SCNVector3(spawnPos.x + 0.2, spawnPos.y, spawnPos.z)
        groundNode.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        groundNode.physicsBody?.collisionBitMask = PhysicsCategory.hero.rawValue
        groundNode.physicsBody!.contactTestBitMask = PhysicsCategory.hero.rawValue
        groundNode.physicsBody?.restitution = 0.0
        groundNode.name = "ground"
        groundNode.castsShadow = true
        sceneView.scene.rootNode.addChildNode(groundNode)
        
        
        //3d Text
        
        scoreLabel = SCNText(string: "Score: 0", extrusionDepth: 0.2)
        scoreLabel.font = UIFont(name: "Arial", size: 4)
        scoreLabel.firstMaterial!.diffuse.contents = UIColor.blue
        
        let (scoreLableMinVec, scoreLableMaxVec)  = scoreLabel.boundingBox
        let scoreBound = SCNVector3(x: scoreLableMaxVec.x - scoreLableMinVec.x, y: scoreLableMaxVec.y - scoreLableMinVec.y, z: scoreLableMaxVec.z - scoreLableMinVec.z)
        scoreNode = SCNNode(geometry: scoreLabel)
        scoreNode.pivot = SCNMatrix4MakeTranslation(scoreBound.x * 0.5, 0 , 0)
        
        scoreNode.position = SCNVector3(spawnPos.x + 0.2, spawnPos.y + 0.16, spawnPos.z)
        scoreNode.scale = SCNVector3(0.0125, 0.0125, 0.0125)
        sceneView.scene.rootNode.addChildNode(scoreNode)
        
        // gameover label
        gameOverLabel = SCNText(string: "GAMEOVER !!!",
                                extrusionDepth: 0.2)
        gameOverLabel.font = UIFont(name: "Arial", size: 4)
        gameOverLabel.firstMaterial!.diffuse.contents = UIColor.red
        let (gameOverLabelMinVec, gameOverLabelMaxVec) = gameOverLabel.boundingBox
        let goBound = SCNVector3(x: gameOverLabelMaxVec.x - gameOverLabelMinVec.x, y: gameOverLabelMaxVec.y - gameOverLabelMinVec.y, z: gameOverLabelMaxVec.z - gameOverLabelMinVec.z)
        gameOverNode = SCNNode(geometry: gameOverLabel)
        gameOverNode.pivot = SCNMatrix4MakeTranslation(goBound.x * 0.5, 0 , 0)
        gameOverNode.position = SCNVector3(spawnPos.x + 0.2, spawnPos.y + 0.08, spawnPos.z)
        gameOverNode.scale = SCNVector3(0.02, 0.02, 0.2)
        sceneView.scene.rootNode.addChildNode(gameOverNode)
        gameOverNode.isHidden = true
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let location = touches.first!.location(in: sceneView)
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        let hitTestArray = sceneView.hitTest(location, types: [.estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent])
        for result in hitTestArray {
            if(!bGameSetup){
                let spawnPos = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y, z: result.worldTransform.columns.3.z)
                if(bPlaneAdded) {
                    setupGame(spawnPos)
                    plane.isHidden = true
                    bGameSetup = true
                }
            } else {
                if(!bGameOver){
                    hero.jump()
                } else{
                    bGameOver = false
                    gameOverNode.isHidden = true
                }
            }
        }
    }

    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if( (contact.nodeA.name == "hero" && contact.nodeB.name == "ground") || (contact.nodeA.name == "ground" && contact.nodeB.name == "hero") ){
            if(hero.isGrounded == false){
                hero.isGrounded = true
                hero.playRunAnim()
                print("ground in contact with hero")
            }
        }
        
        if( (contact.nodeA.name == "hero" && contact.nodeB.name == "ground") || (contact.nodeA.name == "ground" && contact.nodeB.name == "hero") ){
            if(hero.isGrounded == false){
                hero.isGrounded = true
                hero.playRunAnim()
                print("ground in contact with hero")
            }
        }
        
        if( (contact.nodeA.name == "hero" && contact.nodeB.name == "enemy") || (contact.nodeA.name == "enemy" && contact.nodeB.name == "hero") ){
            bGameOver = true
            enemy.reset()
            gameOverNode.isHidden = false
            print("GameOver")
        }
    }
    
    func renderer(_ aRenderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if(bGameSetup){
            if(!bGameOver){
                enemy.update()
                scoreLabel.string = "Score: \(enemy.score)"
            }
        }
    }
}

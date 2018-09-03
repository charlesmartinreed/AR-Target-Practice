//
//  Scene.swift
//  Project2a
//
//  Created by Charles Martin Reed on 9/2/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import SpriteKit
import ARKit
import GameplayKit //for its random factions

class Scene: SKScene {
    
    //MARK:- SCENE PROPERTIES
    //remaining label, target counter, timer, targetCount to show the remaining targets at a given time.
    let remainingLabel = SKLabelNode() //should be static as its part of HUD
    var timer: Timer?
    var targetsCreated = 0
    var targetCount = 0 {
        didSet {
            remainingLabel.text = "Remaining: \(targetCount)"
        }
    }
    
    //we need to track when the game begin to understand how quickly the player cleared out the targets
    let startTime = Date()
    
    override func didMove(to view: SKView) {
        
        remainingLabel.fontSize = 36
        remainingLabel.fontName = "AmericanTypewriter"
        remainingLabel.color = .white
        remainingLabel.position = CGPoint(x: 0, y: view.frame.midY - 50)
        addChild(remainingLabel)
        targetCount = 0 //triggers the didSet as soon as the game starts
        
        //create the timer and ask it to run createTarget every two minutes
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { timer in
            
            self.createTarget()
        })
    }
    
    //MARK:- Game Mechanic methods
    func createTarget() {
        //will manage how many targets have been created, end game if targetsCreated == 20. If so, invalidate timer and destroy assets.
        //we want the targets to appear randomly, around the character, so we're going to perform two matrix mulitplications. One matrix will generate a random X rotation, another matrix will generate a random y rotation and will be multiplied by the first matrix.
        //then we'll create an identity matrix and adjust the Z position 1.5 m into the screen and multiply THAT against the combined x/y position matrix.
        //we position targets by rotating some amount of x, y and then moving 1.5 m in that direction.
        
        if targetsCreated == 20 {
            timer?.invalidate()
            timer = nil
            return
        }
        
        targetsCreated += 1
        targetCount += 1
        
        //find the scene view we are drawing into
        guard let sceneView = self.view as? ARSKView else { return }
        
        //get access to a random number generator
        let random = GKRandomSource.sharedRandom()
        
        //create a random X rotation
        //Float.pi is half a circle, multiplying by 2 gets us 360 degrees
        //nextUniform returns a floating point number between 0 and 1
        let xRotation = matrix_float4x4(SCNMatrix4MakeRotation(Float.pi * 2 * random.nextUniform(), 1, 0, 0))
        
        //create a random Y rotation
        let yRotation = matrix_float4x4(SCNMatrix4MakeRotation(Float.pi * 2 * random.nextUniform(), 0, 1, 0))
        
        //combine the random X/Y rotations
        let rotation = simd_mul(xRotation, yRotation)
        
        //move forward 1.5 meters into the screen
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -1.5
        
        //combine the translation with our earlier X/Y rotation
        let transform = simd_mul(rotation, translation)
        
        //create an anchor at the finished position and add it to the scene's AR session
        let anchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: anchor)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       //grab the touch info and the location, use that information to detect when sprite was hit
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hit = nodes(at: location)
        
        //if there's a sprite here, remove it using our animation and decrement the targetCount
        if let sprite = hit.first {
            
            let scaleOut = SKAction.scale(to: 2, duration: 0.2)
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let group = SKAction.group([scaleOut, fadeOut])
            let sequence = SKAction.sequence([group, SKAction.removeFromParent()])
            
            sprite.run(sequence)
            targetCount -= 1
            
            if targetsCreated == 20 && targetCount == 0 {
                gameOver()
            }
            
        }
    }
    
    func gameOver() {
        //remove remaining label
        remainingLabel.removeFromParent()
        
        //create new sprite node from GameOver
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        addChild(gameOver)
        
        //create a new date and determine how long that date is from the startTime
        let timeTaken = Date().timeIntervalSince(startTime)
        
        //create SKLabelNode to show that time
        let timeLabel = SKLabelNode(text: "Time taken: \(Int(timeTaken)) seconds")
        timeLabel.fontSize = 36
        timeLabel.fontName = "AmericanTypewriter"
        timeLabel.color = .white
        timeLabel.position = CGPoint(x: 0, y: -view!.frame.midY + 50)
        
        addChild(timeLabel)
        
        
    }
}

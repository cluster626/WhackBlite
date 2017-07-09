//
//  GameHint.swift
//  WhackBlite
//
//  Created by Fumlar on 2017-07-09.
//  Copyright © 2017 Fumlar. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameHint: SKScene {
    
    var hintTitle: eCATextLayer = eCATextLayer()
    var hint: eCATextLayer = eCATextLayer()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = UIColor.black
        let titleSize = CGSize(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.height / 6)
        let titleOrigin = CGPoint(x: UIScreen.main.bounds.width / 2 - titleSize.width / 2, y: 0)
        
        hintTitle.frame = CGRect(origin: titleOrigin, size: titleSize)

        hintTitle.opacity = 1
        hintTitle.contentsScale = UIScreen.main.scale
        hintTitle.alignmentMode = kCAAlignmentCenter
        hintTitle.foregroundColor = UIColor.white.cgColor
        //font
        let systemFont = UIFont.systemFont(ofSize: 0.0)
        let fontStringRef = systemFont.fontName as CFString
        hintTitle.font = fontStringRef
        hintTitle.fontSize = UIScreen.main.bounds.width / 20
        hintTitle.string = NSLocalizedString("gameHintTitle", comment: "")
        
        self.view?.layer.addSublayer(hintTitle)
        
        let hinteSize = CGSize(width: UIScreen.main.bounds.width * 3 / 4, height: UIScreen.main.bounds.height / 2)
        let hintOrigin = CGPoint(x: UIScreen.main.bounds.width / 2 - hinteSize.width / 2, y: titleSize.height)
        
        hint.frame = CGRect(origin: hintOrigin, size: hinteSize)
        
        hint.opacity = 1
        hint.contentsScale = UIScreen.main.scale
        hint.alignmentMode = kCAAlignmentCenter
        hint.foregroundColor = UIColor.white.cgColor
        //font
        hint.font = fontStringRef
        hint.fontSize = UIScreen.main.bounds.width / 20
        hint.string = NSLocalizedString("gameHint", comment: "")
        hint.isWrapped = true
        self.view?.layer.addSublayer(hint)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        //print("test ball at \(testBall.layer.frame)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let transition = SKTransition.crossFade(withDuration: 1.0)
        let nextScene = GameScene(size: scene!.size)
        nextScene.scaleMode = .aspectFill
        scene?.view?.presentScene(nextScene, transition: transition)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
}

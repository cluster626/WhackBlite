//
//  GameScene.swift
//  WhackBlite
//
//  Created by Fumlar on 2017-06-04.
//  Copyright © 2017 Fumlar. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    enum possibleSpawns:UInt32 {
        case TopFirst
        case TopSecond
        case TopThird
        case TopFourth
        case BottomFirst
        case BottomSecond
        case BottomThird
        case BottomFourth
        case LeftFirst
        case LeftSecond
        case LeftThird
        case LeftFourth
        case RightFirst
        case RightSecond
        case RightThird
        case RightFourth
        private static let count: possibleSpawns.RawValue = {
            var maxValue: UInt32 = 0
            while let _ = possibleSpawns(rawValue: maxValue) {
                maxValue += 1
            }
            return maxValue
        }()
        
        static func randomSpawn() -> possibleSpawns {
            let rand = arc4random_uniform(count)
            return possibleSpawns(rawValue: rand)!
        }
    }
    //var parentVC = UIApplication.shared.keyWindow?.rootViewController
    var mainGrid: Grid = Grid.init(withBlockSize: UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height ? (UIScreen.main.bounds.size.width - 40) / 4 : (UIScreen.main.bounds.size.height - 40) / 4)
    var totalScoreLabel: eCATextLayer = eCATextLayer()
    var timerLabel: eCATextLayer = eCATextLayer()
    var highScoreLabel: eCATextLayer = eCATextLayer()
    var totalScore: Int = 0
    var timeRemaining: Int = 60
    var canSpawnBall: Bool = true
    var gameInProgress: Bool = true
    var canResetGrid: Bool = true
    //var appOpenedForTheFirstTime: Bool = false
    //var testBall: Ball = Ball.init(initRect: CGRect.zero, ofType: Ball.type.randomType(), toBlock: Block.init(initRect: CGRect.zero, typeOfBlock: Block.type.randomType(), x:0, y:0), fromDirection: Ball.direction.randomDirection())
    
    override func didMove(to view: SKView) {
        self.backgroundColor = UIColor.black
        //appOpenedForTheFirstTime = true //assume first time lauch so init label does not start timer
        initLabels()
        //add grid to view
        mainGrid.addGridToView(toView: self.view!)
        NotificationCenter.default.addObserver(self, selector: #selector(handleEndGame), name: NSNotification.Name.init(rawValue: "GridFinishedAnimation"), object: mainGrid)
        NotificationCenter.default.addObserver(self, selector: #selector(restartGame), name: NSNotification.Name.init(rawValue: "GridFinishedReset"), object: mainGrid)
/*
         
         if (!UserDefaults.standard.bool(forKey: "appFirstLaunched")) {
         UserDefaults.standard.set(true, forKey: "appFirstLaunched")
         UserDefaults.standard.synchronize()
         
         let alertViewtitle = NSLocalizedString("gameHintTitle", comment: "")
         let alertViewMessage = NSLocalizedString("gameHint", comment: "")
         let alertViewButtonTitle = NSLocalizedString("okButton", comment: "")
         let alertView = UIAlertController.init(title: alertViewtitle, message: alertViewMessage, preferredStyle: UIAlertControllerStyle.alert)
         let actionButon = UIAlertAction.init(title: alertViewButtonTitle, style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
         self.startTimer()
         })
         alertView.addAction(actionButon)
         parentVC?.present(alertView, animated: true, completion: nil)
         
         }
         */
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //NSLog("GS: touched began")
        //incTotalScore()
        let touchLocation = touches.first?.location(in: self.view)
        let xTouchLoc = touchLocation?.x
        let yTouchLoc = touchLocation?.y
        if gameInProgress {
            for r in 0..<mainGrid.numberOfRows {
                for c in 0..<mainGrid.numberOfColumns {
                    if mainGrid.blocks[r][c].layer.frame.contains(CGPoint(x: xTouchLoc! - mainGrid.grid.frame.origin.x, y: yTouchLoc! - mainGrid.grid.frame.origin.y)) {//to calibrate location due to difference introduced by mainGrid's grid layer
                        if canBlockRotate(theBlock: mainGrid.blocks[r][c]) {
                            mainGrid.blocks[r][c].rotateClockwise90()
                            //testBall.test_resetPosition()
                        }
                        return
                    }
                }
            }
            
            //testBall.move()
            if canSpawnBall {
                var ballSpawnedSuccessfully = spawnAndStartBall() //this is so that the ball won't spawn at positions like at top of first block with blockType WBR or WTL, which won't increase the ball's score at all
                while !ballSpawnedSuccessfully {
                    ballSpawnedSuccessfully = spawnAndStartBall()
                }
                canSpawnBall = false
            }
            //add a ball whenever we touch somewhere else
        } else if canResetGrid {
            canResetGrid = false //prevent the grid from being reset multiple times
            totalScoreLabel.removeFromSuperlayer()
            mainGrid.resetGridForNewGame()
            highScoreLabel.removeFromSuperlayer()
        }

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameInProgress {
            canSpawnBall = true
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        //print("test ball at \(testBall.layer.frame)")


    }
    
    func updateTotalScore() {
        totalScoreLabel.string = "\(totalScore)"
    }
    
    func resetTotalScore() {
        totalScore = 0
        updateTotalScore()
    }
    
    func incTotalScore(amount: Int) {
        totalScore += amount
        totalScore = totalScore < 0 ? 0 : totalScore //prevent totalScore from being negative
        updateTotalScore()
    }
    
    /*func totalScorePenalty() {
        if totalScore > 0 {
            totalScore -= 1
        }
        updateTotalScore()
    }*/
    
    func updateTimerLabel() {
        timerLabel.string = "\(timeRemaining)"
    }
    
    func resetTimerLabel() {
        timeRemaining = 60
        updateTimerLabel()
    }
    
    func decTimeRemaining() {
        timeRemaining -= 1
        updateTimerLabel()
    }
    
    @objc func handleEndGame() {
        canResetGrid = true
        var highScore = 0
        if (totalScore > UserDefaults.standard.integer(forKey: "highScore")) {
            highScore = totalScore
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
        highScoreLabel.string = NSLocalizedString("highScore", comment: "") + "\(UserDefaults.standard.integer(forKey: "highScore"))"
        self.view?.layer.addSublayer(highScoreLabel)
    }
    
    @objc func restartGame() {
        initLabels()
        gameInProgress = true
        canResetGrid = false
    }
    
    func initLabels() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        totalScoreLabel.frame = CGRect(x: mainGrid.grid.frame.origin.x - Grid.blockSize / 4, y: mainGrid.grid.frame.origin.y - Grid.blockSize / 2, width: Grid.blockSize, height: Grid.blockSize / 2)
        CATransaction.commit()
        //CATransaction.setDisableActions(true)
        resetTotalScore()
        totalScoreLabel.opacity = 1
        totalScoreLabel.contentsScale = UIScreen.main.scale
        totalScoreLabel.alignmentMode = CATextLayerAlignmentMode.center
        totalScoreLabel.foregroundColor = UIColor.white.cgColor
        //font
        let systemFont = UIFont.systemFont(ofSize: 0.0)
        let fontStringRef = systemFont.fontName as CFString
        totalScoreLabel.font = fontStringRef
        totalScoreLabel.fontSize = Grid.blockSize * 0.3
        self.view?.layer.addSublayer(totalScoreLabel)
        
        //init timer label
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        timerLabel.frame = CGRect(x: totalScoreLabel.frame.origin.x + Grid.blockSize * 3.7, y:totalScoreLabel.frame.origin.y, width: Grid.blockSize / 2, height: Grid.blockSize / 2)
        CATransaction.commit()
        resetTimerLabel()
        timerLabel.opacity = 1
        timerLabel.contentsScale = UIScreen.main.scale
        timerLabel.alignmentMode = CATextLayerAlignmentMode.center
        timerLabel.foregroundColor = UIColor.white.cgColor
        //timer font
        timerLabel.font = fontStringRef
        timerLabel.fontSize = totalScoreLabel.fontSize
        self.view?.layer.addSublayer(timerLabel)

        //semi-init
        highScoreLabel.frame = CGRect(x: 0, y: mainGrid.grid.frame.origin.y - Grid.blockSize, width: UIScreen.main.bounds.width, height: Grid.blockSize / 2)
        highScoreLabel.opacity = 1
        highScoreLabel.contentsScale = UIScreen.main.scale
        highScoreLabel.alignmentMode = CATextLayerAlignmentMode.center
        highScoreLabel.foregroundColor = UIColor.white.cgColor
        //score font
        highScoreLabel.font = fontStringRef
        highScoreLabel.fontSize = totalScoreLabel.fontSize
        startTimer()
    }
    
    func startTimer() {
        let wait = SKAction.wait(forDuration: TimeInterval(1))
        let run = SKAction.run {
            if self.timeRemaining < 2 {
                self.gameInProgress = false
                self.canResetGrid = false
                if self.timeRemaining < 1 {
                    self.removeAction(forKey: "TimerAction")
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.totalScoreLabel.frame.origin = CGPoint(x: UIScreen.main.bounds.width / 2 - self.totalScoreLabel.frame.width / 2, y: UIScreen.main.bounds.height / 2 - self.totalScoreLabel.frame.height / 2)
                    self.totalScoreLabel.fontSize = Grid.blockSize * 0.4
                    CATransaction.commit()
                    //self.totalScoreLabel.fontSize = 30
                    self.view?.layer.addSublayer(self.totalScoreLabel)
                    self.timerLabel.frame.origin = self.totalScoreLabel.frame.origin
                    self.timerLabel.opacity = 0
                    self.timerLabel.removeFromSuperlayer()
                    NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "NowYouWantToKillYourself"), object: nil)
                    self.mainGrid.setBlocksToResultScreen()
                }
            }
            self.decTimeRemaining()
        }
        let repeatedAction = SKAction.repeatForever(SKAction.sequence([wait, run]))
        self.run(repeatedAction, withKey: "TimerAction")
    }
    
    func spawnAndStartBall() -> Bool {
        //testing
        var testBall: Ball
        let ballDiameter = Grid.blockSize / 3 //did not use radius since height and width need whole diameter
        let positionToSpawn = possibleSpawns.randomSpawn()
        var directionToSpawn: Ball.direction
        var ballTypeToSpawn: Ball.type
        switch positionToSpawn {
        case possibleSpawns.TopFirst:
            /*if (mainGrid.blocks[0][0].blockType == Block.type.WBL || mainGrid.blocks[0][0].blockType == Block.type.WBR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[0][0].blockType {
            case Block.type.WBL:
                ballTypeToSpawn = Ball.type.Black
            case Block.type.WBR:
                return false
            case Block.type.WTL:
                return false
            case Block.type.WTR:
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Top
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[0][0].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[0][0].layer.frame.origin.y - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[0][0], fromDirection: directionToSpawn)
        case possibleSpawns.TopSecond:
            if (mainGrid.blocks[0][1].blockType == Block.type.WBL || mainGrid.blocks[0][1].blockType == Block.type.WBR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Top
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[0][1].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[0][1].layer.frame.origin.y - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[0][1], fromDirection: directionToSpawn)
        case possibleSpawns.TopThird:
            if (mainGrid.blocks[0][2].blockType == Block.type.WBL || mainGrid.blocks[0][2].blockType == Block.type.WBR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Top
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[0][2].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[0][2].layer.frame.origin.y - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[0][2], fromDirection: directionToSpawn)
        case possibleSpawns.TopFourth:
            /*if (mainGrid.blocks[0][3].blockType == Block.type.WBL || mainGrid.blocks[0][3].blockType == Block.type.WBR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
             }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[0][3].blockType {
            case Block.type.WBL:
                return false
            case Block.type.WBR:
                ballTypeToSpawn = Ball.type.Black
            case Block.type.WTL:
                ballTypeToSpawn = Ball.type.White
            case Block.type.WTR:
                return false
            }
            directionToSpawn = Ball.direction.Top
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[0][3].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[0][3].layer.frame.origin.y - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[0][3], fromDirection: directionToSpawn)
        case possibleSpawns.LeftFirst:
            /*if (mainGrid.blocks[0][0].blockType == Block.type.WBR || mainGrid.blocks[0][0].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
             }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[0][0].blockType {
            case Block.type.WBL:
                ballTypeToSpawn = Ball.type.White
            case Block.type.WBR:
                return false
            case Block.type.WTL:
                return false
            case Block.type.WTR:
                ballTypeToSpawn = Ball.type.Black
            }
            directionToSpawn = Ball.direction.Left
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[0][0].layer.frame.origin.x - ballDiameter / 2, y:mainGrid.blocks[0][0].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[0][0], fromDirection: directionToSpawn)
        case possibleSpawns.LeftSecond:
            if (mainGrid.blocks[1][0].blockType == Block.type.WBR || mainGrid.blocks[1][0].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Left
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[1][0].layer.frame.origin.x - ballDiameter / 2, y:mainGrid.blocks[1][0].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[1][0], fromDirection: directionToSpawn)
        case possibleSpawns.LeftThird:
            if (mainGrid.blocks[2][0].blockType == Block.type.WBR || mainGrid.blocks[2][0].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Left
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[2][0].layer.frame.origin.x - ballDiameter / 2, y:mainGrid.blocks[2][0].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[2][0], fromDirection: directionToSpawn)
        case possibleSpawns.LeftFourth:
            /*if (mainGrid.blocks[3][0].blockType == Block.type.WBR || mainGrid.blocks[3][0].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[3][0].blockType {
            case Block.type.WBL:
                return false
            case Block.type.WBR:
                ballTypeToSpawn = Ball.type.Black
            case Block.type.WTL:
                ballTypeToSpawn = Ball.type.White
            case Block.type.WTR:
                return false
            }
            directionToSpawn = Ball.direction.Left
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[3][0].layer.frame.origin.x - ballDiameter / 2, y:mainGrid.blocks[3][0].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[3][0], fromDirection: directionToSpawn)
        case possibleSpawns.BottomFirst:
            /*if (mainGrid.blocks[3][0].blockType == Block.type.WTL || mainGrid.blocks[3][0].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[3][0].blockType {
            case Block.type.WBL:
                return false
            case Block.type.WBR:
                ballTypeToSpawn = Ball.type.White
            case Block.type.WTL:
                ballTypeToSpawn = Ball.type.Black
            case Block.type.WTR:
                return false
            }
            directionToSpawn = Ball.direction.Bottom
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[3][0].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[3][0].layer.frame.origin.y + Grid.blockSize - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[3][0], fromDirection: directionToSpawn)
        case possibleSpawns.BottomSecond:
            if (mainGrid.blocks[3][1].blockType == Block.type.WTL || mainGrid.blocks[3][1].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Bottom
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[3][1].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[3][1].layer.frame.origin.y + Grid.blockSize - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[3][1], fromDirection: directionToSpawn)
        case possibleSpawns.BottomThird:
            if (mainGrid.blocks[3][2].blockType == Block.type.WTL || mainGrid.blocks[3][2].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Bottom
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[3][2].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[3][2].layer.frame.origin.y + Grid.blockSize - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[3][2], fromDirection: directionToSpawn)
        case possibleSpawns.BottomFourth:
            /*if (mainGrid.blocks[3][3].blockType == Block.type.WTL || mainGrid.blocks[3][3].blockType == Block.type.WTR) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[3][3].blockType {
            case Block.type.WBL:
                ballTypeToSpawn = Ball.type.White
            case Block.type.WBR:
                return false
            case Block.type.WTL:
                return false
            case Block.type.WTR:
                ballTypeToSpawn = Ball.type.Black
            }
            directionToSpawn = Ball.direction.Bottom
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[3][3].layer.frame.origin.x + Grid.blockSize / 2 - ballDiameter / 2, y:mainGrid.blocks[3][3].layer.frame.origin.y + Grid.blockSize - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[3][3], fromDirection: directionToSpawn)
        case possibleSpawns.RightFirst:
            /*if (mainGrid.blocks[0][3].blockType == Block.type.WTL || mainGrid.blocks[0][3].blockType == Block.type.WBL) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[0][3].blockType {
            case Block.type.WBL:
                return false
            case Block.type.WBR:
                ballTypeToSpawn = Ball.type.White
            case Block.type.WTL:
                ballTypeToSpawn = Ball.type.Black
            case Block.type.WTR:
                return false
            }
            directionToSpawn = Ball.direction.Right
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[0][3].layer.frame.origin.x + Grid.blockSize - ballDiameter / 2, y:mainGrid.blocks[0][3].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[0][3], fromDirection: directionToSpawn)
        case possibleSpawns.RightSecond:
            if (mainGrid.blocks[1][3].blockType == Block.type.WTL || mainGrid.blocks[1][3].blockType == Block.type.WBL) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Right
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[1][3].layer.frame.origin.x + Grid.blockSize - ballDiameter / 2, y:mainGrid.blocks[1][3].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[1][3], fromDirection: directionToSpawn)
        case possibleSpawns.RightThird:
            if (mainGrid.blocks[2][3].blockType == Block.type.WTL || mainGrid.blocks[2][3].blockType == Block.type.WBL) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Right
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[2][3].layer.frame.origin.x + Grid.blockSize - ballDiameter / 2, y:mainGrid.blocks[2][3].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[2][3], fromDirection: directionToSpawn)
        case possibleSpawns.RightFourth:
            /*if (mainGrid.blocks[3][3].blockType == Block.type.WTL || mainGrid.blocks[3][3].blockType == Block.type.WBL) {
                ballTypeToSpawn = Ball.type.Black
            } else {
                ballTypeToSpawn = Ball.type.White
            }*/
            //we replace if with switch only for blocks that sit at the corner because in some cases scoring is not possible
            switch mainGrid.blocks[3][3].blockType {
            case Block.type.WBL:
                ballTypeToSpawn = Ball.type.Black
            case Block.type.WBR:
                return false
            case Block.type.WTL:
                return false
            case Block.type.WTR:
                ballTypeToSpawn = Ball.type.White
            }
            directionToSpawn = Ball.direction.Right
            testBall = Ball.init(initRect: CGRect(x:mainGrid.blocks[3][3].layer.frame.origin.x + Grid.blockSize - ballDiameter / 2, y:mainGrid.blocks[3][3].layer.frame.origin.y + Grid.blockSize / 2 - ballDiameter / 2, width:ballDiameter, height:ballDiameter), ofType: ballTypeToSpawn, toBlock: mainGrid.blocks[3][3], fromDirection: directionToSpawn)
        }
        
        testBall.addLayersToLayer(toLayer: mainGrid.grid)
        NotificationCenter.default.addObserver(self, selector: #selector(getNextBlockWithCurrentBlockIndex(note:)), name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: testBall)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { 
            testBall.move()
        }
        return true
    }
    
    //it also handles ball scoring by comparing when the nextBlock will cause the ball to turn
    @objc func getNextBlockWithCurrentBlockIndex(note: Notification) {
        let userInformation = note.userInfo as NSDictionary?
        let direction = userInformation?.object(forKey: "direction") as! Ball.direction
        let currentblock = userInformation?.object(forKey: "currentBlock") as! Block
        let theBall = note.object as! Ball
        //print("received note in getNextBlockWithCurrentBlockIndex, current ball score \(theBall.score)")
        switch direction {
        case Ball.direction.Top:
            switch currentblock.blockType {
            case Block.type.WBL:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.yIndex == mainGrid.numberOfColumns - 1) {
                        //print("Exiting TOP WBL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) ||  mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1]
                        theBall.directionToBlock = Ball.direction.Left
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            case Block.type.WBR:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.yIndex == 0) {
                        //print("Exiting TOP WBR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            //theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1]
                        theBall.directionToBlock = Ball.direction.Right
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            case Block.type.WTL:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.yIndex == 0) {
                        //print("Exiting TOP WTL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1]
                        theBall.directionToBlock = Ball.direction.Right
                    }
                }
            case Block.type.WTR:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.yIndex == mainGrid.numberOfColumns - 1) {
                        //print("Exiting TOP WTR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1]
                        theBall.directionToBlock = Ball.direction.Left
                    }
                }
            }
        case Ball.direction.Bottom:
            switch currentblock.blockType {
            case Block.type.WBL:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.yIndex == 0) {
                        //print("Exiting BOT WBL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1]
                        theBall.directionToBlock = Ball.direction.Right
                    }
                }
            case Block.type.WBR:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.yIndex == mainGrid.numberOfColumns - 1) {
                        //print("Exiting BOT WBR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1]
                        theBall.directionToBlock = Ball.direction.Left
                    }
                }
            case Block.type.WTL:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.yIndex == mainGrid.numberOfColumns - 1) {
                        //print("Exiting BOT WTL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex + 1]
                        theBall.directionToBlock = Ball.direction.Left
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            case Block.type.WTR:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.yIndex == 0) {
                        //print("Exiting BOT WTR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "penalizeScore"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            //theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex][currentblock.yIndex - 1]
                        theBall.directionToBlock = Ball.direction.Right
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            }
        case Ball.direction.Left:
            switch currentblock.blockType {
            case Block.type.WBL:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.xIndex == mainGrid.numberOfRows - 1) {
                        //print("Exiting LEF WBL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            //theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Top
                    }
                }
            case Block.type.WBR:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.xIndex == 0) {
                        //print("Exiting LEF WBR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            //theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Bottom
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            case Block.type.WTL:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.xIndex == 0) {
                        //print("Exiting LEF WTL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Bottom
                    }
                }

            case Block.type.WTR:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.xIndex == mainGrid.numberOfRows - 1) {
                        //print("Exiting LEF WTR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Top
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            }
        case Ball.direction.Right:
            switch currentblock.blockType {
            case Block.type.WBL:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.xIndex == 0) {
                        //print("Exiting RIG WBL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Bottom
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            case Block.type.WBR:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.xIndex == mainGrid.numberOfRows - 1) {
                        //print("Exiting RIG WBR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Top
                    }
                }
            case Block.type.WTL:
                switch theBall.ballType {
                case Ball.type.Black:
                    if (currentblock.xIndex == mainGrid.numberOfRows - 1) {
                        //print("Exiting RIG WTL, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex + 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Top
                    }
                case Ball.type.White:
                    //print("Collission with block of opposite colour")
                    break
                }
            case Block.type.WTR:
                switch theBall.ballType {
                case Ball.type.Black:
                    //print("Collission with block of opposite colour")
                    break
                case Ball.type.White:
                    if (currentblock.xIndex == 0) {
                        //print("Exiting RIG WTR, the ball had score \(theBall.score)")
                        if theBall.needToSumbitScore {
                            incTotalScore(amount: theBall.score)
                        }
                        theBall.nextBlockToAccess = Block.init(initRect: CGRect.zero, typeOfBlock: Block.type(rawValue: (currentblock.blockType.rawValue + 2) % Block.type.count)!, x: 0, y: 0) // this basically makes a dummy ball with flipped orientation which blocks the ball from going on further, ideally
                        //now we should remove observer I guess
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.init(rawValue: "WhatIsNextBlock"), object: theBall)
                    } else {
//                        if theBall.score < maxBallScoreAllowed && (mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 1) % Block.type.count) || mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex].blockType == Block.type(rawValue: (theBall.nextBlockToAccess.blockType.rawValue + 3) % Block.type.count)) {
//                            theBall.incScore() //we detected a turn
//                        }
                        theBall.nextBlockToAccess = mainGrid.blocks[currentblock.xIndex - 1][currentblock.yIndex]
                        theBall.directionToBlock = Ball.direction.Bottom
                    }
                }
            }
        }
    }
    
    func canBlockRotate(theBlock: Block) -> Bool {
        return theBlock.ballAccessCount == 0 ? true : false
    }
}

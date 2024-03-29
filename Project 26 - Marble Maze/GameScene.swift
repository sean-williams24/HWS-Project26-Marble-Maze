//
//  GameScene.swift
//  Project 26 - Marble Maze
//
//  Created by Sean Williams on 05/11/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//

import CoreMotion
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var motionManger: CMMotionManager?
    var isGameOver = false
    var level = 0
    var allNodes: [SKSpriteNode] = []
    var teleportPosition: [CGPoint] = []
    var teleportingEnabled = true
    
    enum CollisionTypes: UInt32 {
        case player = 1
        case wall = 2
        case star = 4
        case vortex = 8
        case teleport = 16
        case finish = 32
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background.jpg")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel()
        createPlayer(at: CGPoint(x: 96, y: 672))
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManger = CMMotionManager()
        motionManger?.startAccelerometerUpdates()
    }
    
    
    
    func loadLevel() {
        level += 1
        
        guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else {
            fatalError("Could not find level\(level).txt in the app bundle.")
        }
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load level1.txt from the app bundle.")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" {
                    // load wall
                    let node = SKSpriteNode(imageNamed: "block")
                    node.position = position
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                    node.physicsBody?.isDynamic = false
                    addChild(node)
                    allNodes.append(node)
                    
                } else if letter == "v"  {
                    // load vortex
                    let node = SKSpriteNode(imageNamed: "vortex")
                    createGameNode(node: node, position: position, name: "vortex", collisionType: CollisionTypes.vortex)
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
                    
                } else if letter == "s"  {
                    // load star
                    let node = SKSpriteNode(imageNamed: "star")
                    createGameNode(node: node, position: position, name: "star", collisionType: CollisionTypes.star)
                    
                } else if letter == "f"  {
                    // load finish
                    let node = SKSpriteNode(imageNamed: "finish")
                    createGameNode(node: node, position: position, name: "finish", collisionType: CollisionTypes.finish)
                
                } else if letter == "t" {
                    // load teleport
                    let node = SKSpriteNode(imageNamed: "bouncer")
                    createGameNode(node: node, position: position, name: "teleport", collisionType: CollisionTypes.teleport)
                    node.scale(to: CGSize(width: node.size.width / 2, height: node.size.width / 2))
                    teleportPosition.append(position)
                    print(teleportPosition)
                } else if letter == " " {
                    // this is an empty space – do nothing!
                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    fileprivate func  createGameNode(node: SKSpriteNode, position: CGPoint, name: String, collisionType: CollisionTypes) {
        node.name = name
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = collisionType.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.position = position
        addChild(node)
        allNodes.append(node)

    }
    
    func createPlayer(at position: CGPoint) {
        player = SKSpriteNode(imageNamed: "player")
        player.position = position
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
        allNodes.append(player)

    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        //if game over is true - dont let user have anymore control over game
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition {
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        
        #else
        if let accelerometerData = motionManger?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50 , dy: accelerometerData.acceleration.x * 50)
        }
        
        #endif
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            teleportingEnabled = true

            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence) { [weak self] in
                self?.createPlayer(at: CGPoint(x: 96, y: 672))
                self?.isGameOver = false
            }
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
            
        } else if node.name == "teleport" {
            if teleportingEnabled {
                let move = SKAction.move(to: node.position, duration: 0.50)
                let scale = SKAction.scale(to: 0.0001, duration: 0.25)
                let remove = SKAction.removeFromParent()
                let sequence = SKAction.sequence([move, scale, remove])
                
                player.run(sequence) { [weak self] in
                    self?.createPlayer(at: (self?.teleportPosition.first!)!)
                }
                
                teleportingEnabled = false
            }

            
        } else if node.name == "finish" {
            // next level?
            for node in allNodes {
                node.removeFromParent()
            }
            allNodes.removeAll()
            createPlayer(at: CGPoint(x: 96, y: 672))
            isGameOver = false
            loadLevel()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    
}

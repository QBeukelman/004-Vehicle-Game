//
//  M_Physics.swift
//  Game
//
//  Created by Quentin Beukelman on 17/05/2023.
//

import Foundation
import SceneKit

extension MapViewController {
    
    // MARK: - PHYS: Static
    func staticPhysBody(type: SCNPhysicsBodyType = .static, shape: SCNGeometry, scale: SCNVector3) -> SCNPhysicsBody {
        let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron, SCNPhysicsShape.Option.scale: scale]))
        body.categoryBitMask = 3
        body.collisionBitMask = 1 | 2
        body.contactTestBitMask = 1 | 2
        body.isAffectedByGravity = false
        return body
    }
    
    
    // MARK: - PHYS: Dynamic
    func dynamicPhysBody(type: SCNPhysicsBodyType = .dynamic, shape: SCNGeometry, scale: SCNVector3) -> SCNPhysicsBody {
        let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.scale: scale]))
        body.categoryBitMask = 1
        body.collisionBitMask = 1 | 2 | 3
        body.contactTestBitMask = 1 | 2 | 3
        body.isAffectedByGravity = true
        body.mass = 40
        return body
    }

    
    // MARK: - OBJ: Add Cones
    func addCones(to tileNode: SCNNode, coneScene: SCNScene) {
        
        print("Adding Dynamic Objs")
        let probability = 1.0
        let randomNumber = Double.random(in: 0..<1)
        if randomNumber < probability {
            let tileWidth: CGFloat = 2.0
            let tileDepth: CGFloat = 1.0
            
            for i in 0..<2 {
                for j in 0..<3 {
                    let randomNumber = Int.random(in: 0..<6)
                    let dynamicObjectsScene = SCNScene(named: "art.scnassets/dynamicObjects.scn")
                    let dynamicNode = dynamicObjectsScene?.rootNode.childNode(withName: "obj\(randomNumber)", recursively: true)
                    let dynamicNodeClone = dynamicNode!.flattenedClone()
                    dynamicNodeClone.name = "cone"
                    
                    let xPosition = tileNode.position.x - (tileWidth * 2) + (CGFloat(i) * tileWidth)
                    let zPosition = tileNode.position.z - (tileDepth * 2) + (CGFloat(j) * tileDepth)
                    dynamicNodeClone.position = SCNVector3(x: xPosition, y: 1, z: zPosition)
                    dynamicNodeClone.scale = SCNVector3(dynamicNodeClone.scale.x, dynamicNodeClone.scale.y, dynamicNodeClone.scale.z)
                    
                    if let geometry = dynamicNodeClone.geometry {
                        dynamicNodeClone.physicsBody = dynamicPhysBody(type: .dynamic, shape: geometry, scale: SCNVector3(dynamicNodeClone.scale.x, dynamicNodeClone.scale.y, dynamicNodeClone.scale.z))
                    }
                    tileNode.addChildNode(dynamicNodeClone)
                }
            }
        }
    }
    
    
    // MARK: - OBJ: Add Traffic Signs
    func addTrafficSigns(to tileNode: SCNNode, coneScene: SCNScene) {
        let probability = 0.6
        let randomNumber = Double.random(in: 0..<1)
        if randomNumber < probability {
            let tileWidth: CGFloat = 3.0
            let tileDepth: CGFloat = 3.0
            
            for i in 0..<2 {
                for j in 0..<1 {
                    let randomNumber = Int.random(in: 0..<5)
                    let dynamicObjectsScene = SCNScene(named: "art.scnassets/Traffic.scn")
                    let dynamicNode = dynamicObjectsScene?.rootNode.childNode(withName: "obj\(randomNumber)", recursively: true)
                    let dynamicNodeClone = dynamicNode!.flattenedClone()
                    dynamicNodeClone.name = "cone"
                    
                    let xPosition = tileNode.position.x - (tileWidth * 2) + (CGFloat(i) * tileWidth)
                    let zPosition = tileNode.position.z - (tileDepth * 2) + (CGFloat(j) * tileDepth)
                    dynamicNodeClone.position = SCNVector3(x: xPosition, y: 1, z: zPosition)
                    dynamicNodeClone.scale = SCNVector3(dynamicNodeClone.scale.x, dynamicNodeClone.scale.y, dynamicNodeClone.scale.z)
                    
                    if let geometry = dynamicNodeClone.geometry {
                        dynamicNodeClone.physicsBody = dynamicPhysBody(type: .dynamic, shape: geometry, scale: SCNVector3(dynamicNodeClone.scale.x, dynamicNodeClone.scale.y, dynamicNodeClone.scale.z))
                    }
                    tileNode.addChildNode(dynamicNodeClone)
                }
            }
        }
    }
    
}



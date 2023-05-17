//
//  VehicleLoader.swift
//  Game
//
//  Created by Quentin Beukelman on 17/05/2023.
//

import Foundation
import SceneKit

class VehicleLoader {
    
    func addVehicle(scene: SCNScene, vehicle: SCNPhysicsVehicle? = nil, chassisNode: SCNNode? = nil)
        -> (vehicle: SCNPhysicsVehicle, chassisNode: SCNNode) {
            let chassisNode = scene.rootNode.childNode(withName: "car", recursively: true)!
            
            let body = SCNPhysicsBody.dynamic()
            body.allowsResting = false
            body.mass = 600
            body.restitution = 0.1
            body.friction = 0
            body.rollingFriction = 0.5
            chassisNode.physicsBody = body
            scene.rootNode.addChildNode(chassisNode)
            
            // Add Wheels
            let wheelnode0 = chassisNode.childNode(withName: "wheelLocator_FL", recursively: true)!
            let wheelnode1 = chassisNode.childNode(withName: "wheelLocator_FR", recursively: true)!
            let wheelnode2 = chassisNode.childNode(withName: "wheelLocator_RL", recursively: true)!
            let wheelnode3 = chassisNode.childNode(withName: "wheelLocator_RR", recursively: true)!
            let wheel0 = SCNPhysicsVehicleWheel(node: wheelnode0)
            let wheel1 = SCNPhysicsVehicleWheel(node: wheelnode1)
            let wheel2 = SCNPhysicsVehicleWheel(node: wheelnode2)
            let wheel3 = SCNPhysicsVehicleWheel(node: wheelnode3)
                
            wheel0.suspensionStiffness = 0.5
            wheel1.suspensionStiffness = 0.5
            wheel2.suspensionStiffness = 0.5
            wheel3.suspensionStiffness = 0.5
            
            wheel0.maximumSuspensionTravel = 500.0
            wheel1.maximumSuspensionTravel = 500.0
            wheel2.maximumSuspensionTravel = 500.0
            wheel3.maximumSuspensionTravel = 500.0
            
            wheel0.suspensionRestLength = 0.5
            wheel1.suspensionRestLength = 0.5
            wheel2.suspensionRestLength = 0.5
            wheel3.suspensionRestLength = 0.5
            
            wheel0.suspensionCompression = 0.5
            wheel1.suspensionCompression = 0.5
            wheel2.suspensionCompression = 0.5
            wheel3.suspensionCompression = 0.5
            
            wheel0.frictionSlip = 0.08
            wheel1.frictionSlip = 0.08
            wheel2.frictionSlip = 0.03
            wheel3.frictionSlip = 0.03
            
            let vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!, wheels: [wheel1, wheel0, wheel3, wheel2])
            chassisNode.position = SCNVector3(x: 40, y: 2, z: 40)
            chassisNode.physicsBody?.categoryBitMask = 2
            chassisNode.physicsBody?.contactTestBitMask = 1
            return (vehicle, chassisNode)
    }
    
    
    func addVehicle2(scene: SCNScene, vehicle2: SCNPhysicsVehicle? = nil, chassisNode2: SCNNode? = nil)
        -> (vehicle2: SCNPhysicsVehicle, chassisNode2: SCNNode) {
            let chassisNode2 = scene.rootNode.childNode(withName: "car_2", recursively: true)!
            
            let body = SCNPhysicsBody.dynamic()
            body.allowsResting = false
            body.mass = 600
            body.restitution = 0.1
            body.friction = 0
            body.rollingFriction = 0.5
            chassisNode2.physicsBody = body
            scene.rootNode.addChildNode(chassisNode2)
            
            // Add Wheels
            let wheelnode0 = chassisNode2.childNode(withName: "wheelLocator_FL_2", recursively: true)!
            let wheelnode1 = chassisNode2.childNode(withName: "wheelLocator_FR_2", recursively: true)!
            let wheelnode2 = chassisNode2.childNode(withName: "wheelLocator_RL_2", recursively: true)!
            let wheelnode3 = chassisNode2.childNode(withName: "wheelLocator_RR_2", recursively: true)!
            let wheel0 = SCNPhysicsVehicleWheel(node: wheelnode0)
            let wheel1 = SCNPhysicsVehicleWheel(node: wheelnode1)
            let wheel2 = SCNPhysicsVehicleWheel(node: wheelnode2)
            let wheel3 = SCNPhysicsVehicleWheel(node: wheelnode3)
            
            wheel0.suspensionStiffness = 0.5
            wheel1.suspensionStiffness = 0.5
            wheel2.suspensionStiffness = 0.5
            wheel3.suspensionStiffness = 0.5
            
            wheel0.maximumSuspensionTravel = 500.0
            wheel1.maximumSuspensionTravel = 500.0
            wheel2.maximumSuspensionTravel = 500.0
            wheel3.maximumSuspensionTravel = 500.0
            
            wheel0.suspensionRestLength = 0.5
            wheel1.suspensionRestLength = 0.5
            wheel2.suspensionRestLength = 0.5
            wheel3.suspensionRestLength = 0.5
            
            wheel0.suspensionCompression = 0.5
            wheel1.suspensionCompression = 0.5
            wheel2.suspensionCompression = 0.5
            wheel3.suspensionCompression = 0.5
            
            wheel0.frictionSlip = 0.08
            wheel1.frictionSlip = 0.08
            wheel2.frictionSlip = 0.03
            wheel3.frictionSlip = 0.03
            
            let vehicle2 = SCNPhysicsVehicle(chassisBody: chassisNode2.physicsBody!, wheels: [wheel1, wheel0, wheel3, wheel2])
            chassisNode2.position = SCNVector3(x: 40, y: 2, z: 40)
            chassisNode2.physicsBody?.categoryBitMask = 2
            chassisNode2.physicsBody?.contactTestBitMask = 1
            return (vehicle2, chassisNode2)
    }
    
    
    
}

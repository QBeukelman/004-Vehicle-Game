//
//  MapViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 09/05/2023.
//

import Foundation
import SceneKit
import QuartzCore
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class MapViewController: NSViewController, SCNSceneRendererDelegate, NSWindowDelegate   {
    
    
    @IBOutlet var mapSceneView: SCNView!
    
    // Scene
    var scnView: SCNView!
    var scene: SCNScene!
    var currentVehicle: SCNPhysicsVehicle!
    var opponentVehicle: SCNPhysicsVehicle!
    var currentVehiceChassis: SCNNode!
    
    let vehicleLoader = VehicleLoader()
    
    var speedLabelString: String!
    var scoreLabelString: String!
    var compassLabelString: String!
    
    // Map
    var currentCenterMapNumber: CGFloat!
    var map: [[String]]?
    var currentMapNumber: CGFloat?
    var mapString = ""
    var maxMapIndex: Int! = 0
    
    // Vehicle 1 = Host
    var vehicle: SCNPhysicsVehicle!
    var chassisNode: SCNNode!
    var vehicleCameraNode: SCNNode!
    var cameraNode: SCNNode!
    var speedLabelNode: SCNNode!
    var scoreLabelNode: SCNNode!
    var compassLabelNode: SCNNode!
    var currentVehicleSpeed: CGFloat! = 0.0
    var currentScore: Int! = 0
    
    // Vehicle 2 = Guest
    var vehicle2: SCNPhysicsVehicle!
    var chassisNode2: SCNNode!
    var cameraNode2: SCNNode!
    
    // Online
    let queue = DispatchQueue(label: "com.example.sharedDict", attributes: .concurrent)
    var uid: String = ""
    var roomID: String = ""
    var hostID: String = ""
    var guestID: String = ""
    
    // Online Vehicle Position
    var countdownTimer: Timer!
    var currentChassisNodeRead: SCNNode!
    var currentChassisNodeWrite: SCNNode!
    var realtimeListnerChildRef: DatabaseReference?
    var refHandle: DatabaseHandle?
    var firabaseListener: ListenerRegistration?
    var ref: DatabaseReference?
    let db = Firestore.firestore()
    
    var oppUID: String!
    var oppUserName: String!
    var oppNameLabelNode: SCNNode!
    var oppNameLabelString: String!
    var opponentChassisNode: SCNNode!
    
    var inputDict: [String: Any] = [
        "w": false,
        "d": false,
        "s": false,
        "a": false,
        "posX": 0,
        "posY": 0,
        "posZ": 0,
        "rotX": 0,
        "rotY": 0,
        "rotZ": 0,
        "rotW": 0,
    ]
    
    // MARK: - View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scene
        scene = SCNScene(named: "art.scnassets/MapTiles.scn")!
        scnView = self.view as? SCNView
        scnView.frame = CGRect(x: 0, y: 0, width: 2000, height: 1000)
        scnView.showsStatistics = true
        
        scnView.scene = scene
        ref = Database.database().reference()

        // Map
        mapSceneView.delegate = self
        cubeMaterial.diffuse.contents = NSColor.white
        cubeGeometry.firstMaterial = cubeMaterial
        getMapString { retrievedMapString in
            if let retrievedMapString = retrievedMapString {
                self.mapString = retrievedMapString
                self.placeMapTiles(mapNumber: 0, currentTileIndex: self.mapString[self.mapString.index(self.mapString.startIndex, offsetBy: 0)].wholeNumberValue ?? 0)
                self.placeMapTiles(mapNumber: 100, currentTileIndex: self.mapString[self.mapString.index(self.mapString.startIndex, offsetBy: 1)].wholeNumberValue ?? 0)
                
                // Vehicle
                self.cameraNode = self.scene.rootNode.childNode(withName: "camera", recursively: true)
                self.cameraNode2 = self.scene.rootNode.childNode(withName: "camera_2", recursively: true)
                (self.vehicle, self.chassisNode) = self.vehicleLoader.addVehicle(scene: self.scene, vehicle: self.vehicle, chassisNode: self.chassisNode)
                (self.vehicle2, self.chassisNode2) = self.vehicleLoader.addVehicle2(scene: self.scene, vehicle2: self.vehicle2, chassisNode2: self.chassisNode2)
                self.scene.physicsWorld.addBehavior(self.vehicle)
                self.scene.physicsWorld.addBehavior(self.vehicle2)
                
                // Online
                self.assignRoles()
                self.getOppDocument()
                self.multiplayerObserve()
                self.listenToRoom()
                
                // Game
                self.addEventListner()
                self.gameLoopCustom()
                
            }
        }

        print("----- Room Launched -----")
        print("uid: \(uid)")
        print("host: \(hostID)")
        print("guest: \(guestID)")
        print("room: \(roomID)")

    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        guard let window = view.window else {
            return
        }
        window.delegate = self
        scnView.scene?.physicsWorld.contactDelegate = self
    }
    
    // MARK: - WINDOW: Should Close
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("-- Window Closed -- ")
        cleanCloseWindow()
        return true
    }
    
    // MARK: - WINDOW: Did Close
    func cleanCloseWindow() {
        db.collection("rooms").document(roomID).setData([
            "status": "closed"
        ], merge: true)
        
        scnView.scene = nil
        print("scene set to (nil)")
        
        realtimeListnerChildRef?.removeObserver(withHandle: refHandle!)
        print("realtime listner removed")
        
        firabaseListener?.remove()
        print("Firebase listner removed")
        
        // Delete Room
    }
    
    
    // MARK: - GAME: Set Up Scene
    func assignRoles() {
        
        scnView.showsStatistics = true
        
        if (hostID == uid) {
            currentVehicle = vehicle
            currentVehiceChassis = chassisNode
            scnView.pointOfView = self.cameraNode
            opponentVehicle = vehicle2
            opponentChassisNode = chassisNode2
            currentChassisNodeWrite = chassisNode
            oppUID = guestID
            
            for childNode in chassisNode2.childNodes {
                if childNode.name == "scoreLabel_2" || childNode.name == "compassLabel_2" {
                    childNode.removeFromParentNode()
                }
            }
            speedLabelString = "speedLabel"
            scoreLabelString = "scoreLabel"
            compassLabelString = "compassLabel"
            oppNameLabelString = "speedLabel_2"
        }
        if (guestID == uid) {
            currentVehicle = vehicle2
            currentVehiceChassis = chassisNode2
            scnView.pointOfView = self.cameraNode2
            opponentVehicle = vehicle
            opponentChassisNode = chassisNode
            currentChassisNodeWrite = chassisNode2
            oppUID = hostID
            
            for childNode in chassisNode.childNodes {
                if childNode.name == "scoreLabel" || childNode.name == "compassLabel" {
                    childNode.removeFromParentNode()
                }
            }
            speedLabelString = "speedLabel_2"
            scoreLabelString = "scoreLabel_2"
            compassLabelString = "compassLabel_2"
            oppNameLabelString = "speedLabel"
        }
    }
    
    func setOppName() {
        print("oppNameLabelString: \(oppNameLabelString!)")
        print("oppChassisNode: \(opponentChassisNode)")
        if let oppNameLabelNode = opponentChassisNode.childNode(withName: oppNameLabelString!, recursively: false) {
            if let textNameGeometry = oppNameLabelNode.geometry as? SCNText {
                print("setting name")
                textNameGeometry.string = "\(oppUserName!)"
            } else {
                print("Faild to set opp name label")
            }
        } else {
            print("Faild to get opp name label")
        }
    }
    
    
    
    
    // MARK: - GAME: Loop
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateOpponentVehiclePosition()
    }
    
    func gameLoopCustom() {
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            
            self.queue.sync {
                if let wValue = self.inputDict["w"] as? Bool, let sValue = self.inputDict["s"] as? Bool {
                    if wValue || sValue {
                        self.addCubesAtWheels()
                    }
                }
            }

            self.updateSpeedLabel()
            self.printVehicleOrientation()

            let start = 0
            let end = 5000
            let step = 100

            for x in stride(from: start, through: end, by: step) {
                let xFloat = CGFloat(x)
                if xFloat <= self.currentVehiceChassis.presentation.position.x && self.currentVehiceChassis.presentation.position.x <= (xFloat + CGFloat(step)) {
                    let newMapNumber = xFloat
                    if self.currentMapNumber != newMapNumber {
                        self.currentMapNumber = newMapNumber
                        self.updateMapTilesIfNeeded(currentMapNumber: self.currentMapNumber!, vehiclePosition: self.chassisNode.presentation.position)
                    }
                    break
                }
            }
        }
    }

    
    
    // MARK: - DASH: Speed
    func updateSpeedLabel() {
        if let speedLabelNode = currentVehiceChassis.childNode(withName: speedLabelString, recursively: false) {
            let speed = currentVehicle.speedInKilometersPerHour
            let roundedSpeed = round(speed * 100) / 10 // Round to the nearest decimal point
            currentVehicleSpeed = roundedSpeed
            
            if let textSpeedGeometry = speedLabelNode.geometry as? SCNText {
                textSpeedGeometry.string = "\(Int(roundedSpeed))"
            }
        }
        if let scoreLabelNode = currentVehiceChassis.childNode(withName: scoreLabelString, recursively: true) {
            if let textScoreGeometry = scoreLabelNode.geometry as? SCNText {
                textScoreGeometry.string = "\(currentScore!)"
            }
        }
    }
    
    // MARK: - DASH: Compass
    func printVehicleOrientation() {
        let orientation = Double(currentVehiceChassis.presentation.worldOrientation.y)
        if let compassLabelNode = currentVehiceChassis.childNode(withName: compassLabelString, recursively: true) {
            if (orientation > 0.9) {
                if let textCompassGeometry = compassLabelNode.geometry as? SCNText {
                    textCompassGeometry.string = "W"
                }
            }
            if (orientation < 0.9 && orientation > 0.37) {
                if let textCompassGeometry = compassLabelNode.geometry as? SCNText {
                    textCompassGeometry.string = "N"
                }
            }
            if (orientation < 0.37 && orientation > -0.37) {
                if let textCompassGeometry = compassLabelNode.geometry as? SCNText {
                    textCompassGeometry.string = "E"
                }
            }
            if (orientation < -0.37) {
                if let textCompassGeometry = compassLabelNode.geometry as? SCNText {
                    textCompassGeometry.string = "S"
                }
            }
        }
    }

    
    // MARK: - VEHICLE: Key Press
    func addEventListner() {
        let eventMonitorDown = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in
            self?.handleKeyDownEvent(event: event)
            return event
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDownEvent(event: event)
        }
        
        let eventMonitorUp = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event -> NSEvent? in
            self?.handleKeyUpEvent(event: event)
            return event
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUpEvent(event: event)
        }
    }

    
    
    
    // MARK: - ANIMATE: Cubes at Wheels
    func addCubesAtWheels() {
        
        var wheelNodes: [SCNNode] = []
        
        if (hostID == uid) {
            currentVehicle = vehicle
            scnView.pointOfView = self.cameraNode
            opponentVehicle = vehicle2
            
            wheelNodes = [
                chassisNode.childNode(withName: "wheelLocator_FL", recursively: true)!,
                chassisNode.childNode(withName: "wheelLocator_FR", recursively: true)!,
                chassisNode.childNode(withName: "wheelLocator_RL", recursively: true)!,
                chassisNode.childNode(withName: "wheelLocator_RR", recursively: true)!
            ]
        }
        if (guestID == uid) {
            currentVehicle = vehicle2
            scnView.pointOfView = self.cameraNode2
            opponentVehicle = vehicle
            
            wheelNodes = [
                chassisNode2.childNode(withName: "wheelLocator_FL_2", recursively: true)!,
                chassisNode2.childNode(withName: "wheelLocator_FR_2", recursively: true)!,
                chassisNode2.childNode(withName: "wheelLocator_RL_2", recursively: true)!,
                chassisNode2.childNode(withName: "wheelLocator_RR_2", recursively: true)!
            ]
        }

        // Create a clone of the cube geometry
        let cubeClone = CloneableBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        
        for wheelNode in wheelNodes {
            let cubeNode = cubeClone.flattenedClone()
            cubeNode.position = wheelNode.presentation.worldPosition
            scene.rootNode.addChildNode(cubeNode)
            
            let randomSize = CGFloat.random(in: 0.2...0.9)
            cubeNode.scale = SCNVector3(x: randomSize, y: randomSize, z: randomSize)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.0
                cubeNode.opacity = 0.0
                cubeNode.position.y += 1 // move cubeNode upwards during fade out
                SCNTransaction.commit()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    cubeNode.removeFromParentNode()
                }
            }
        }
    }
    
    
    // MARK: - ANIMATE: Add Cubes at Cone
    func contactWithCone(_ coneNode: SCNNode) {
        for _ in 1...10 {
            let cube = SCNBox(width: CGFloat.random(in: 0.1...0.5), height: CGFloat.random(in: 0.1...0.5), length: CGFloat.random(in: 0.1...0.5), chamferRadius: 0.01)
            cube.firstMaterial?.diffuse.contents = NSColor.white
            let cubeNode = SCNNode(geometry: cube)
            cubeNode.position = coneNode.position
            self.scnView?.scene!.rootNode.addChildNode(cubeNode)
        }
    }

    
    // MARK: ANIMATE: Handle Contact
    // Create a shared box geometry object to reuse for all cubes
    let cubeGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
    let cubeMaterial = SCNMaterial()
    func handleContact(nodePosition: SCNVector3) {
        guard (scnView.scene?.rootNode.childNodes.first(where: { $0.categoryBitMask == 1 })) != nil else {
            return
        }
        for _ in 1...5 {
            let cubeNode = SCNNode(geometry: cubeGeometry)
            cubeNode.position = nodePosition
            scnView.scene?.rootNode.addChildNode(cubeNode)
            let impulseDirection = SCNVector3(CGFloat.random(in: -1...1) * 2, CGFloat.random(in: -1...1) * 2, CGFloat.random(in: -1...1) * 2)
            let moveAction = SCNAction.move(by: impulseDirection, duration: 1.0)
            let vanishDelay = TimeInterval.random(in: 0.01...0.02)
            let removeAction = SCNAction.sequence([
                SCNAction.wait(duration: vanishDelay),
                SCNAction.fadeOut(duration: 0.1),
                SCNAction.removeFromParentNode()
            ])
            cubeNode.runAction(SCNAction.sequence([moveAction, removeAction]))
        }
    }
} // End Class



// MARK: - EXTENSION: Contact Deligate
// Cone = 1
// Vehicle = 2
// Floor/Road = 3
extension MapViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        if nodeA.physicsBody?.categoryBitMask == 2 && nodeB.physicsBody?.categoryBitMask == 1 {
            let contactPosition = contact.nodeB.presentation.worldPosition
            handleContact(nodePosition: contactPosition)
            
            // Points
            currentScore += 1
        }
    }
}



// MARK: - CLASS: Cube Class
class CloneableBox: SCNBox {
    func flattenedClone() -> SCNNode {
        let cloneGeometry = self.copy() as! SCNBox
        let cloneNode = SCNNode(geometry: cloneGeometry)
        cloneNode.name = "cube"
        return cloneNode.flattenedClone()
    }
}

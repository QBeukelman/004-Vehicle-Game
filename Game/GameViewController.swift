//
//  GameViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 20/04/2023.
//

import SceneKit
import QuartzCore
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class GameViewController: NSViewController, NSWindowDelegate {
    
    // Scene
    var scnView: SCNView!
    var scene: SCNScene!
    var currentVehicle: SCNPhysicsVehicle!
    var opponentVehicle: SCNPhysicsVehicle!
    
    // Vehicle 1 = Host
    var vehicle: SCNPhysicsVehicle!
    var chassisNode: SCNNode!
    var cameraNode: SCNNode!
    
    // Vehicle 2 = Guest
    var vehicle2: SCNPhysicsVehicle!
    var chassisNode2: SCNNode!
    var cameraNode2: SCNNode!
    
    // Online
    var uid: String = ""
    var roomID: String = ""
    var hostID: String = ""
    var guestID: String = ""
    var ref: DatabaseReference?
    
    // Online Vehicle Position
    var countdownTimer: Timer!
    var currentChassisNodeRead: SCNNode!
    var currentChassisNodeWrite: SCNNode!
    var realtimeListnerChildRef: DatabaseReference?
    var refHandle: DatabaseHandle?
    var firabaseListener: ListenerRegistration?
    let db = Firestore.firestore()
    
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
        
        scene = SCNScene(named: "art.scnassets/newScene.scn")!
        scnView = self.view as? SCNView
        scnView.frame = CGRect(x: 0, y: 0, width: 2000, height: 1000)
        scnView.scene = scene
        // scnView.debugOptions = SCNDebugOptions.showPhysicsShapes
        
        cameraNode = scene.rootNode.childNode(withName: "camera", recursively: true)
        cameraNode2 = scene.rootNode.childNode(withName: "camera_2", recursively: true)

        ref = Database.database().reference()
        
        addLights()
        addEventListner()
        addPhysicsFloor()
        addPhysicsRoad()
        addPhysicsBuildings()
        addPhysicsDynamic()
        addPhysicsDynamicWarehouse()
        addVehicle()
        addVehicle2()
        multiplayerObserve()
        setUpScene()
        
        // Create a timer that calls the addCubesAtWheels() function every second
        let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if (self.inputDict["w"] as? Bool == true || self.inputDict["s"] as? Bool == true) {
                self.addCubesAtWheels()
            }
        }
        
        updateOpponentVehiclePosition()
        listenToRoom()
        
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
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("-- Window Closed -- ")
        cleanCloseWindow()
        return true
    }
    
    // MARK: - Close Window
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
    }
    
    // MARK: - Delete Room
    func deleteRoom() {
        db.collection("rooms").document(roomID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        
        // Delete RealTime node
        ref?.child(roomID).removeValue()
    }
    
    // MARK: - Listen To Room
    func listenToRoom() {
        firabaseListener = db.collection("rooms").document(roomID).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
                
            }
            if let roomStatus = documentSnapshot? ["status"] as? String {
                if (roomStatus == "closed") {
                    print("roomStatus = closed")
                    for window in NSApplication.shared.windows {
                        if (window.title == "Game") {
                            self.cleanCloseWindow()
                            self.deleteRoom()
                            window.close()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Set Up Scene
    func setUpScene() {
        
        scnView.showsStatistics = true
        
        if (hostID == uid) {
            currentVehicle = vehicle
            scnView.pointOfView = self.cameraNode
            opponentVehicle = vehicle2
        }
        if (guestID == uid) {
            currentVehicle = vehicle2
            scnView.pointOfView = self.cameraNode2
            opponentVehicle = vehicle
        }
    }
    
    
    // MARK: - Add Vehicle - Host
    func addVehicle() {
        chassisNode = scene!.rootNode.childNode(withName: "car", recursively: true)!
        
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
    
        wheel0.suspensionStiffness = 0.4
        wheel1.suspensionStiffness = 0.4
        wheel2.suspensionStiffness = 0.4
        wheel3.suspensionStiffness = 0.4
        
        wheel0.maximumSuspensionTravel = 2000.0
        wheel1.maximumSuspensionTravel = 2000.0
        wheel2.maximumSuspensionTravel = 2000.0
        wheel3.maximumSuspensionTravel = 2000.0

        wheel0.suspensionRestLength = 0.3
        wheel1.suspensionRestLength = 0.3
        wheel2.suspensionRestLength = 0.3
        wheel3.suspensionRestLength = 0.3
        
        wheel0.suspensionDamping = 0.3
        wheel1.suspensionDamping = 0.3
        wheel2.suspensionDamping = 0.3
        wheel3.suspensionDamping = 0.3
        
        wheel0.frictionSlip = 0.08
        wheel1.frictionSlip = 0.08
        wheel2.frictionSlip = 0.03
        wheel3.frictionSlip = 0.03
        
        vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!, wheels: [wheel1, wheel0, wheel3, wheel2])
        scene.physicsWorld.addBehavior(vehicle)
        
        chassisNode.position = SCNVector3(x: 0, y: 2, z: -10)
        chassisNode.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
    }
    
    
    // MARK: - Add Vehicle - Guest
    func addVehicle2() {
        chassisNode2 = scene!.rootNode.childNode(withName: "car_2", recursively: true)!
        
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
    
        wheel0.suspensionStiffness = 0.4
        wheel1.suspensionStiffness = 0.4
        wheel2.suspensionStiffness = 0.4
        wheel3.suspensionStiffness = 0.4
        
        wheel0.maximumSuspensionTravel = 2000.0
        wheel1.maximumSuspensionTravel = 2000.0
        wheel2.maximumSuspensionTravel = 2000.0
        wheel3.maximumSuspensionTravel = 2000.0

        wheel0.suspensionRestLength = 0.3
        wheel1.suspensionRestLength = 0.3
        wheel2.suspensionRestLength = 0.3
        wheel3.suspensionRestLength = 0.3
        
        wheel0.suspensionDamping = 0.3
        wheel1.suspensionDamping = 0.3
        wheel2.suspensionDamping = 0.3
        wheel3.suspensionDamping = 0.3
        
        wheel0.frictionSlip = 0.08
        wheel1.frictionSlip = 0.08
        wheel2.frictionSlip = 0.03
        wheel3.frictionSlip = 0.03
        
        vehicle2 = SCNPhysicsVehicle(chassisBody: chassisNode2.physicsBody!, wheels: [wheel1, wheel0, wheel3, wheel2])
        scene.physicsWorld.addBehavior(vehicle2)
        
        chassisNode2.position = SCNVector3(x: 0, y: 2, z: 10)
        chassisNode2.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0) // was 180
    }
    
    
    // MARK: - Add Cubes at Wheels
    func addCubesAtWheels() {
        let wheelNodes = [
            chassisNode2.childNode(withName: "wheelLocator_FL_2", recursively: true)!,
            chassisNode2.childNode(withName: "wheelLocator_FR_2", recursively: true)!,
            chassisNode2.childNode(withName: "wheelLocator_RL_2", recursively: true)!,
            chassisNode2.childNode(withName: "wheelLocator_RR_2", recursively: true)!
        ]
        
        for wheelNode in wheelNodes {
            let cube = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
            let cubeNode = SCNNode(geometry: cube)
            cubeNode.position = wheelNode.presentation.worldPosition
            scene.rootNode.addChildNode(cubeNode)
            let randomSize = CGFloat.random(in: 0.02...0.2)
            cube.width = randomSize
            cube.height = randomSize
            cube.length = randomSize
            
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


    
    
    
    let roadCategoryBitMask: Int = 1 << 0 // 1
    let floorCategoryBitMask: Int = 1 << 1 // 2
    let coneCategoryBitMask: Int = 1 << 2 // 4
    
    // MARK: - Physics Road
    func addPhysicsRoad() {
        let road = scene!.rootNode.childNode(withName: "road", recursively: true)!
        func floorPhysBody(type: SCNPhysicsBodyType = .static, shape: SCNGeometry, scale: SCNVector3 = SCNVector3(road.scale.x, road.scale.y, road.scale.z)) -> SCNPhysicsBody {
                    
            // Create Physics Body and set Physics Properties
            let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron, SCNPhysicsShape.Option.scale: scale]))
                
            // Physics Config
            body.isAffectedByGravity = false
            return body
        }
        road.physicsBody = floorPhysBody(type: .static, shape: road.geometry!)
        road.physicsBody?.categoryBitMask = roadCategoryBitMask
        road.physicsBody?.contactTestBitMask = floorCategoryBitMask | coneCategoryBitMask
    }
    
    // MARK: - Physics Floor
    func addPhysicsFloor() {
        let floor = scene!.rootNode.childNode(withName: "floor", recursively: true)!
        func floorPhysBody(type: SCNPhysicsBodyType = .static, shape: SCNGeometry, scale: SCNVector3 = SCNVector3(floor.scale.x, floor.scale.y, floor.scale.z)) -> SCNPhysicsBody {
                    
            // Create Physics Body and set Physics Properties
            let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron, SCNPhysicsShape.Option.scale: scale]))
                
            // Physics Config
            body.isAffectedByGravity = false
            return body
        }
        floor.physicsBody = floorPhysBody(type: .static, shape: floor.geometry!)
        floor.physicsBody?.categoryBitMask = floorCategoryBitMask
        floor.physicsBody?.contactTestBitMask = roadCategoryBitMask | coneCategoryBitMask
    }
    
    // MARK: - Physics Dynamic
    func addPhysicsDynamic() {
        var i: Int = 0
        let parentNode = scene!.rootNode.childNode(withName: "Cones", recursively: true)
        parentNode?.enumerateChildNodes { (childNode, stop) in
            let coneNode = scene!.rootNode.childNode(withName: "Cone\(i)", recursively: true)!
            func dynamicObjectPhysBody(type: SCNPhysicsBodyType = .dynamic, shape: SCNGeometry, scale: SCNVector3 = SCNVector3(coneNode.scale.x, coneNode.scale.y, coneNode.scale.z)) -> SCNPhysicsBody {
                let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.scale: scale]))
                body.isAffectedByGravity = true
                body.mass = 40
                return body
            }
            coneNode.physicsBody = dynamicObjectPhysBody(type: .dynamic, shape: coneNode.geometry!)
            coneNode.physicsBody?.categoryBitMask = coneCategoryBitMask
            coneNode.physicsBody?.contactTestBitMask = roadCategoryBitMask | floorCategoryBitMask
            i += 1
        }
    }
    
    func addPhysicsDynamicWarehouse() {
        var i: Int = 0
        let parentNode = scene!.rootNode.childNode(withName: "warehouseObjects", recursively: true)
        parentNode?.enumerateChildNodes { (childNode, stop) in
            let coneNode = scene!.rootNode.childNode(withName: "obj\(i)", recursively: true)!
            func dynamicObjectPhysBody(type: SCNPhysicsBodyType = .dynamic, shape: SCNGeometry, scale: SCNVector3 = SCNVector3(coneNode.scale.x, coneNode.scale.y, coneNode.scale.z)) -> SCNPhysicsBody {
                let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.scale: scale]))
                body.isAffectedByGravity = true
                body.mass = 40
                return body
            }
            coneNode.physicsBody = dynamicObjectPhysBody(type: .dynamic, shape: coneNode.geometry!)
            coneNode.physicsBody?.categoryBitMask = coneCategoryBitMask
            coneNode.physicsBody?.contactTestBitMask = roadCategoryBitMask | floorCategoryBitMask
            i += 1
        }
    }
    
    // MARK: - Physics Buildings
    func addPhysicsBuildings() {
        var i: Int = 0
        let parentNode = scene!.rootNode.childNode(withName: "Buildings", recursively: true)
        parentNode?.enumerateChildNodes { (childNode, stop) in
            let buildingNode = scene!.rootNode.childNode(withName: "building\(i)", recursively: true)!
            func dynamicObjectPhysBody(type: SCNPhysicsBodyType = .static, shape: SCNGeometry, scale: SCNVector3 = SCNVector3(buildingNode.scale.x, buildingNode.scale.y, buildingNode.scale.z)) -> SCNPhysicsBody {
                let body = SCNPhysicsBody(type: type, shape: SCNPhysicsShape(geometry: shape, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron, SCNPhysicsShape.Option.scale: scale]))
                body.isAffectedByGravity = false
                return body
            }
            buildingNode.physicsBody = dynamicObjectPhysBody(type: .static, shape: buildingNode.geometry!)
            buildingNode.physicsBody?.categoryBitMask = coneCategoryBitMask
            buildingNode.physicsBody?.contactTestBitMask = roadCategoryBitMask | floorCategoryBitMask
            i += 1
        }
    }

    
    
    // MARK: - Lights
    func addLights() {
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    // MARK: - Multiplayer Observe
    func multiplayerObserve() {
        // Observe the other player
        if (hostID == uid) {
            realtimeListnerChildRef = ref?.child(roomID).child("guest")
            currentChassisNodeRead = chassisNode2
        }
        if (guestID == uid) {
            realtimeListnerChildRef = ref?.child(roomID).child("host")
            currentChassisNodeRead = chassisNode
        }
            
        refHandle = realtimeListnerChildRef?.observe(.value, with: { snapshot in
            let positionDict = snapshot.value as? [String: Any] ?? [:]
            let w = positionDict["w"] as? Bool
            let d = positionDict["d"] as? Bool
            let a = positionDict["a"] as? Bool
            let s = positionDict["s"] as? Bool
            
            let posX = positionDict["posX"] as? Double
            let posY = positionDict["posY"] as? Double
            let posZ = positionDict["posZ"] as? Double
            let rotX  = positionDict["rotX"] as? Double
            let rotY  = positionDict["rotY"] as? Double
            let rotZ  = positionDict["rotZ"] as? Double
            let rotW  = positionDict["rotW"] as? Double
            
            self.currentChassisNodeRead.position = SCNVector3(x: posX!, y: posY!, z: posZ!)
            self.currentChassisNodeRead.rotation = SCNVector4(x: rotX!, y: rotY!, z: rotZ!, w: rotW!)
            
            print("Input Observed")
            switch (true) {
                case w:
                    self.accelerateDown_opp()
                case d:
                    self.steerRightDown_opp()
                case a:
                    self.steerLeftDown_opp()
                case s:
                    self.breakDown_opp()
                default:
                    self.clearAccelerate_opp()
                    self.clearSteering_opp()
                    self.clearBreak_opp()
            }
        })
    }
    
    // MARK: - Update Opp Vhicle Position
    func updateOpponentVehiclePosition() {
        
        var position: SCNVector3!
        var rotation: SCNVector4!
        
        if (hostID == uid) {
            currentChassisNodeWrite = chassisNode
        }
        if (guestID == uid) {
            currentChassisNodeWrite = chassisNode2
        }
        
        position = currentChassisNodeWrite.presentation.position
        rotation = currentChassisNodeWrite.presentation.rotation
        
        inputDict["posX"] = position.x
        inputDict["posY"] = position.y
        inputDict["posZ"] = position.z
        
        inputDict["rotX"] = rotation.x
        inputDict["rotY"] = rotation.y
        inputDict["rotZ"] = rotation.z
        inputDict["rotW"] = rotation.w
        updateVehicleInput()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            position = self.currentChassisNodeWrite.presentation.position
            rotation = self.currentChassisNodeWrite.presentation.rotation
            
            self.inputDict["posX"] = position.x
            self.inputDict["posY"] = position.y
            self.inputDict["posZ"] = position.z
            
            self.inputDict["rotX"] = rotation.x
            self.inputDict["rotY"] = rotation.y
            self.inputDict["rotZ"] = rotation.z
            self.inputDict["rotW"] = rotation.w
            self.updateVehicleInput()
        }
    }
    
    
    // MARK: - Update Vehicle Input
    func updateVehicleInput() {
        var childRef: DatabaseReference?
        // Update your own input values
        if (hostID == uid) {
            childRef = ref?.child(roomID).child("host")
        }
        if (guestID == uid) {
            childRef = ref?.child(roomID).child("guest")
        }
        childRef?.setValue(inputDict)
    }
    
    // MARK: - LocalControls
    @objc func accelerateDown() {
        currentVehicle.applyEngineForce(300, forWheelAt: 0)
        currentVehicle.applyEngineForce(300, forWheelAt: 1)
        currentVehicle.applyEngineForce(100, forWheelAt: 2)
        currentVehicle.applyEngineForce(100, forWheelAt: 3)
    }
    @objc func steerLeftDown() {
        currentVehicle.setSteeringAngle(0.5, forWheelAt: 0)
        currentVehicle.setSteeringAngle(0.5, forWheelAt: 1)
    }
    @objc func steerRightDown() {
        currentVehicle.setSteeringAngle(-0.5, forWheelAt: 0)
        currentVehicle.setSteeringAngle(-0.5, forWheelAt: 1)
    }
    @objc func breakDown() {
        currentVehicle.applyEngineForce(-100, forWheelAt: 0)
        currentVehicle.applyEngineForce(-100, forWheelAt: 1)
        currentVehicle.applyEngineForce(-100, forWheelAt: 2)
        currentVehicle.applyEngineForce(-100, forWheelAt: 3)
    }
    @objc func clearSteering() {
        currentVehicle.setSteeringAngle(0, forWheelAt: 0)
        currentVehicle.setSteeringAngle(0, forWheelAt: 1)
    }
    @objc func clearAccelerate() {
        currentVehicle.applyEngineForce(0, forWheelAt: 0)
        currentVehicle.applyEngineForce(0, forWheelAt: 1)
        currentVehicle.applyEngineForce(0, forWheelAt: 2)
        currentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func clearBreak() {
        currentVehicle.applyEngineForce(0, forWheelAt: 0)
        currentVehicle.applyEngineForce(0, forWheelAt: 1)
        currentVehicle.applyEngineForce(0, forWheelAt: 2)
        currentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func resetVehiclePosition() {
        currentVehicle.chassisBody.resetTransform()
    }
    
    // MARK: - RealTime Controls
    @objc func accelerateDown_opp() {
        opponentVehicle.applyEngineForce(10, forWheelAt: 0)
        opponentVehicle.applyEngineForce(10, forWheelAt: 1)
        opponentVehicle.applyEngineForce(10, forWheelAt: 2)
        opponentVehicle.applyEngineForce(10, forWheelAt: 3)
    }
    @objc func steerLeftDown_opp() {
        opponentVehicle.setSteeringAngle(0.5, forWheelAt: 0)
        opponentVehicle.setSteeringAngle(0.5, forWheelAt: 1)
    }
    @objc func steerRightDown_opp() {
        opponentVehicle.setSteeringAngle(-0.5, forWheelAt: 0)
        opponentVehicle.setSteeringAngle(-0.5, forWheelAt: 1)
    }
    @objc func breakDown_opp() {
        opponentVehicle.applyEngineForce(-10, forWheelAt: 0)
        opponentVehicle.applyEngineForce(-10, forWheelAt: 1)
        opponentVehicle.applyEngineForce(-10, forWheelAt: 2)
        opponentVehicle.applyEngineForce(-10, forWheelAt: 3)
    }
    @objc func clearSteering_opp() {
        opponentVehicle.setSteeringAngle(0, forWheelAt: 0)
        opponentVehicle.setSteeringAngle(0, forWheelAt: 1)
    }
    @objc func clearAccelerate_opp() {
        opponentVehicle.applyEngineForce(0, forWheelAt: 0)
        opponentVehicle.applyEngineForce(0, forWheelAt: 1)
        opponentVehicle.applyEngineForce(0, forWheelAt: 2)
        opponentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func clearBreak_opp() {
        opponentVehicle.applyEngineForce(0, forWheelAt: 0)
        opponentVehicle.applyEngineForce(0, forWheelAt: 1)
        opponentVehicle.applyEngineForce(0, forWheelAt: 2)
        opponentVehicle.applyEngineForce(0, forWheelAt: 3)
    }
    @objc func resetVehiclePosition_opp() {
        opponentVehicle.chassisBody.resetTransform()
    }
    
    
    // MARK: - KeyDown
    func addEventListner() {
        // add the event listener to the view
        let eventMonitorDown = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (event) -> NSEvent? in
            if event.characters == "a" {
                self.inputDict["a"] = true
                self.updateVehicleInput()
                self.steerLeftDown()
            }
            if event.characters == "d" {
                self.inputDict["d"] = true
                self.updateVehicleInput()
                self.steerRightDown()
            }
            if event.characters == "w" {
                self.inputDict["w"] = true
                self.updateVehicleInput()
                self.accelerateDown()
            }
            if event.characters == "s" {
                self.inputDict["s"] = true
                self.updateVehicleInput()
                self.breakDown()
            }
            if event.characters == "r" {
                self.resetVehiclePosition()
            }
            return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { (event) in
            if event.characters == "a" {
                self.inputDict["a"] = true
                self.updateVehicleInput()
                self.steerLeftDown()
            }
            if event.characters == "d" {
                self.inputDict["d"] = true
                self.updateVehicleInput()
                self.steerRightDown()
            }
            if event.characters == "w" {
                self.inputDict["w"] = true
                self.updateVehicleInput()
                self.accelerateDown()
            }
            if event.characters == "s" {
                self.inputDict["s"] = true
                self.updateVehicleInput()
                self.breakDown()
            }
            if event.characters == "r" {
                self.resetVehiclePosition()
            }
        }
    
        // MARK: - KeyUp
        // add the event listener to the view
        let eventMonitorUp = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { (event) -> NSEvent? in
            if event.characters == "a" {
                self.inputDict["a"] = false
                self.updateVehicleInput()
                self.clearSteering()
            }
            if event.characters == "d" {
                self.inputDict["d"] = false
                self.updateVehicleInput()
                self.clearSteering()
            }
            if event.characters == "w" {
                self.inputDict["w"] = false
                self.updateVehicleInput()
                self.clearAccelerate()
            }
            if event.characters == "s" {
                self.inputDict["s"] = false
                self.updateVehicleInput()
                self.clearBreak()
            }
            return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { (event) in
            if event.characters == "a" {
                self.inputDict["a"] = false
                self.updateVehicleInput()
                self.clearSteering()
            }
            if event.characters == "d" {
                self.inputDict["d"] = false
                self.updateVehicleInput()
                self.clearSteering()
            }
            if event.characters == "w" {
                self.inputDict["w"] = false
                self.updateVehicleInput()
                self.clearAccelerate()
            }
            if event.characters == "s" {
                self.inputDict["s"] = false
                self.updateVehicleInput()
                self.clearBreak()
            }
        }
    }

}

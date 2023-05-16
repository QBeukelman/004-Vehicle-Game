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
    
    // Map
    var currentCenterMapNumber: CGFloat!
    var map: [[String]]?
    var currentMapNumber: CGFloat?
    var mapString = ""
    
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
                self.addVehicle()
                self.addVehicle2()
                
                // Online
                self.setUpScene()
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
    
    
    // MARK: - ONLINE: Set Up Scene
    func setUpScene() {
        
        scnView.showsStatistics = true
        
        if (hostID == uid) {
            currentVehicle = vehicle
            currentVehiceChassis = chassisNode
            scnView.pointOfView = self.cameraNode
            opponentVehicle = vehicle2
            currentChassisNodeWrite = chassisNode
        }
        if (guestID == uid) {
            currentVehicle = vehicle2
            currentVehiceChassis = chassisNode2
            scnView.pointOfView = self.cameraNode2
            opponentVehicle = vehicle
            currentChassisNodeWrite = chassisNode2
        }
        
        print("Current Vehicle: \(currentVehicle!) | Opp Vehicle: \(opponentVehicle!)")
    }
    
    // MARK: - ONLINE: Delete Room
    func deleteRoom() {
        db.collection("rooms").document(roomID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        ref?.child(roomID).removeValue()
    }
    
    // MARK: - ONLINE: Listen To Room
    func listenToRoom() {
        firabaseListener = db.collection("rooms").document(roomID).addSnapshotListener { documentSnapshot, error in
            guard let _ = documentSnapshot else {
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
    
    // MARK: - ONLINE: Get Room
    func getMapString(completion: @escaping (String?) -> Void) {
        let docRef = db.collection("rooms").document(roomID)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let dataMapString = document.data()?["map"] as? String {
                    completion(dataMapString)
                }
            } else {
                print("Room document does not exist")
                completion(nil)
            }
        }
    }

    
    // MARK: - ONLINE: Multiplayer Observe
    func multiplayerObserve() {
        // Observe the other player
        if (hostID == uid) {
            print("Listening to: GUEST")
            realtimeListnerChildRef = ref?.child(roomID).child("guest")
            currentChassisNodeRead = chassisNode2
        }
        if (guestID == uid) {
            print("Listening to: HOST")
            print("Ref: \(ref)")
            realtimeListnerChildRef = ref?.child(roomID).child("host")
            currentChassisNodeRead = chassisNode
        }
        
        print("Observe - currentChassisNodeRead: \(currentChassisNodeRead!)")
        print("RoodID: \(roomID)")
        print("RealTime Ref: \(realtimeListnerChildRef)")
            
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
    
    // MARK: - ONLINE: Update Opp Position
    func updateOpponentVehiclePosition() {
        
        if currentChassisNodeWrite != nil {
            var position: SCNVector3!
            var rotation: SCNVector4!

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
        }
    }
    
    // MARK: - ONLINE: Update Vehicle Input
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
    
    
    // MARK: - GAME LOOP
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateOpponentVehiclePosition()
    }
    
    func gameLoopCustom() {
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if let wValue = self.inputDict["w"] as? Bool, let sValue = self.inputDict["s"] as? Bool {
                if wValue || sValue {
                    self.addCubesAtWheels()
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
        if let speedLabelNode = chassisNode.childNode(withName: "speedLabel", recursively: true) {
            let speed = vehicle.speedInKilometersPerHour
            let roundedSpeed = round(speed * 100) / 10 // Round to the nearest decimal point
            currentVehicleSpeed = roundedSpeed
            
            if let textSpeedGeometry = speedLabelNode.geometry as? SCNText {
                textSpeedGeometry.string = "\(Int(roundedSpeed))"
            }
        }
        if let scoreLabelNode = chassisNode.childNode(withName: "scoreLabel", recursively: true) {
            if let textScoreGeometry = scoreLabelNode.geometry as? SCNText {
                textScoreGeometry.string = "\(currentScore!)"
            }
        }
    }
    
    // MARK: - DASH: Compass
    func printVehicleOrientation() {
        let orientation = Double(chassisNode.presentation.worldOrientation.y)
        if let compassLabelNode = chassisNode.childNode(withName: "compassLabel", recursively: true) {
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


    // MARK: - MAP: Update
    func updateMapTilesIfNeeded(currentMapNumber: CGFloat, vehiclePosition: SCNVector3) {
        getMapString { retrievedMapString in
            if let retrievedMapString = retrievedMapString {
                // Assign the retrieved mapString value to the global variable
                self.mapString = retrievedMapString
                print(self.mapString)
                
                // Rest of your code using the updated mapString...
                print("Current map: \(currentMapNumber)")
                
                let scene = self.scene
                for node in scene!.rootNode.childNodes {
                    if node.name != "SUN"
                        && node.name != "omni"
                        && node.name != "cube"
                        && node.name != "road"
                        && node.name != "car"
                        && node.name != "car_2"
                        && (node.presentation.worldPosition.x > (currentMapNumber + 200)
                            || node.presentation.worldPosition.x < (currentMapNumber - 200)) {
                        print("Removed node: \(node.name!)")
                        node.removeFromParentNode()
                    }
                    if node.name == "road" {
                        for childNode in node.childNodes {
                            if (childNode.presentation.worldPosition.x > (currentMapNumber + 200)
                                || childNode.presentation.worldPosition.x < (currentMapNumber - 100)) {
                                childNode.removeFromParentNode()
                            }
                        }
                    }
                }
                
                
                print("Current Map Number Int: \(Int(currentMapNumber))")
                var currentMapIndex: Int = 0
                
                if (Int(currentMapNumber) == 0){
                    currentMapIndex = 0
                } else if (Int(currentMapNumber) > 0) {
                    currentMapIndex = Int(currentMapNumber) / 100
                }
                
                if currentMapIndex < self.mapString.count {
                    let index = self.mapString.index(self.mapString.startIndex, offsetBy: currentMapIndex)
                    let currentTileIndex = self.mapString[index]
                    print("Current Tile to Render: \(currentTileIndex)")
                    
                    self.placeMapTiles(mapNumber: currentMapNumber + 100, currentTileIndex: (currentTileIndex.wholeNumberValue ?? 0) + 2)
                } else {
                    print("Invalid currentMapIndex")
                }
                
            } else {
                // Handle the case where retrievedMapString is nil
                print("Failed to retrieve mapString")
            }
        }
    }
    
    // MARK: - MAP: Read
    func readMapFile(currentTileIndex: Int) -> [[String]]? {
        let valAtIndex = mapString[mapString.index(mapString.startIndex, offsetBy: currentTileIndex)].wholeNumberValue ?? 0
        print("Read Map at index for adding: map\(valAtIndex)")
        
        guard let fileURL = Bundle.main.url(forResource: "map\(valAtIndex)", withExtension: "txt") else {
            print("File not found")
            return nil
        }
        do {
            let fileContents = try String(contentsOf: fileURL)
            let rows = fileContents.split(separator: "\n")
            var map: [[String]] = []
            for row in rows {
                let cols = row.split(separator: "\t")
                map.append(cols.map({ String($0) }))
            }
            return map
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }

    
    // MARK: - OBJ: Add Floor
    func addFloorToScene(mapNumber: CGFloat) -> [SCNNode] {
        var floorNodes: [SCNNode] = []

        if let floorScene = SCNScene(named: "art.scnassets/map_abstract_floor.scn"),
           let floor = floorScene.rootNode.childNode(withName: "floor", recursively: true) {

            // Clone the floor node
            let clonedFloor = floor.flattenedClone()

            clonedFloor.position = SCNVector3(x: (45 + mapNumber), y: -4.1, z: 45)
            clonedFloor.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)

            // Add a static physics body to the cloned floor node
            if let geometry = clonedFloor.geometry {
                clonedFloor.physicsBody = staticPhysBody(type: .static, shape: geometry, scale: SCNVector3(clonedFloor.scale.x, clonedFloor.scale.y, clonedFloor.scale.z))
            }
            floorNodes.append(clonedFloor)
        } else {
            print("Failed to load floor from scene")
        }
        
        return floorNodes
    }
    
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
        
        let probability = 1.0
        let randomNumber = Double.random(in: 0..<1)
        if randomNumber < probability {
            let tileWidth: CGFloat = 2.0
            let tileDepth: CGFloat = 1.0
            
            for i in 0..<2 {
                for j in 0..<6 {
                    let randomNumber = Int.random(in: 0..<7)
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

    
    // MARK: - MAP: Place Tiles
    func placeMapTiles(mapNumber: CGFloat, currentTileIndex: Int) {
        
        map = readMapFile(currentTileIndex: currentTileIndex)
        
        let tileSize: CGFloat = 10 // 10m x 10m
        let batchNode = SCNNode() // Batching

        // Load road scenes
        guard let roadStraightScene = SCNScene(named: "art.scnassets/roadTiles/Road_Tile.scn"),
              let houseScene = SCNScene(named: "art.scnassets/roadTiles/Road_Tile_House.scn"),
              let factoryScene = SCNScene(named: "art.scnassets/roadTiles/Road_Tile_Factory.scn"),
              let bushScene = SCNScene(named: "art.scnassets/roadTiles/Tree_Tile.scn"),
              let trafficScene = SCNScene(named: "art.scnassets/Traffic.scn"),
              let coneScene = SCNScene(named: "art.scnassets/dynamicObjects.scn") else {
            print("Failed to load road scenes")
            return
        }
        
        var x = 0
        var y = 0
        
        guard let map = map, map.count == 10 && map[0].count == 10 else {
            print("Invalid map")
            return
        }
        
        while y < 10 {
            x = 0 // reset x index at the beginning of each row
            while x < 10 {
                let tileType = map[y][x] as String?
                if let tileType = tileType,
                   let prefix = tileType.first,
                   let suffix = tileType.last,
                   let angle = Int(String(suffix)),
                   angle >= 0 && angle <= 4 {
                    
                    var tileNode: SCNNode!

                    if prefix == "S" {
                        tileNode = roadStraightScene.rootNode.childNodes.first!.flattenedClone()
                    } else if prefix == "T" {
                        tileNode = roadStraightScene.rootNode.childNodes.first!.flattenedClone()
                    } else if prefix == "C" {
                        tileNode = roadStraightScene.rootNode.childNodes.first!.flattenedClone()
                    } else if prefix == "J" {
                        tileNode = roadStraightScene.rootNode.childNodes.first!.flattenedClone()
                        addTrafficSigns(to: tileNode, coneScene: coneScene)
                    } else if prefix == "H" {
                        tileNode = houseScene.rootNode.childNodes.first!.flattenedClone()
                    } else if prefix == "B" {
                        tileNode = bushScene.rootNode.childNodes.first!.flattenedClone()
                    } else if prefix == "F" {
                        tileNode = factoryScene.rootNode.childNodes.first!.flattenedClone()
                        addCones(to: tileNode, coneScene: trafficScene)
                    } else {
                        x += 1
                        continue
                    }
                    
                    if suffix == "0" {
                        tileNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
                    } else if suffix == "1" {
                        tileNode.eulerAngles = SCNVector3(x: 0, y: CGFloat.pi/2, z: 0)
                    } else if suffix == "2" {
                        tileNode.eulerAngles = SCNVector3(x: 0, y: CGFloat.pi, z: 0)
                    } else if suffix == "3" {
                        tileNode.eulerAngles = SCNVector3(x: 0, y: 3*CGFloat.pi/2, z: 0)
                    } else if suffix == "4" {
                        tileNode.eulerAngles = SCNVector3(x: 0, y: CGFloat.pi/2 * CGFloat(angle), z: 0)
                    } else {
                        x += 1
                        continue
                    }
                    
                    tileNode.position = SCNVector3(x: (CGFloat(x) * tileSize) + mapNumber, y: -0.2, z: CGFloat(y) * tileSize)
                    if let geometry = tileNode.geometry {
                        tileNode.physicsBody = staticPhysBody(type: .static, shape: geometry, scale: SCNVector3(tileNode.scale.x, tileNode.scale.y, tileNode.scale.z))
                    }
                    batchNode.addChildNode(tileNode)
                }
                x += 1
            }
            y += 1
        }
        
        // Add Floor
        let floorNodes = addFloorToScene(mapNumber: mapNumber)
        for floorNode in floorNodes {
            scene.rootNode.addChildNode(floorNode)
        }
        batchNode.name = "road"
        scene.rootNode.addChildNode(batchNode)
    }



    
    // MARK: - VEHICLE: Host Vehicle
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
        
        vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!, wheels: [wheel1, wheel0, wheel3, wheel2])
        chassisNode.position = SCNVector3(x: 40, y: 2, z: 40)
        chassisNode.physicsBody?.categoryBitMask = 2
        chassisNode.physicsBody?.contactTestBitMask = 1
        scene.physicsWorld.addBehavior(vehicle)
    }
    
    // MARK: - VEHICLE: Guest Vehicle
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
        
        vehicle2 = SCNPhysicsVehicle(chassisBody: chassisNode2.physicsBody!, wheels: [wheel1, wheel0, wheel3, wheel2])
        chassisNode2.position = SCNVector3(x: 40, y: 2, z: 40)
        chassisNode2.physicsBody?.categoryBitMask = 2
        chassisNode2.physicsBody?.contactTestBitMask = 1
        scene.physicsWorld.addBehavior(vehicle2)
    }
    
    // MARK: - CONTROL: Local
    @objc func accelerateDown() {
        currentVehicle.applyEngineForce(200, forWheelAt: 0)
        currentVehicle.applyEngineForce(200, forWheelAt: 1)
        currentVehicle.applyEngineForce(50, forWheelAt: 2)
        currentVehicle.applyEngineForce(50, forWheelAt: 3)
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
        currentVehicle.applyEngineForce(-50, forWheelAt: 0)
        currentVehicle.applyEngineForce(-50, forWheelAt: 1)
        currentVehicle.applyEngineForce(-50, forWheelAt: 2)
        currentVehicle.applyEngineForce(-50, forWheelAt: 3)
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
    
    // MARK: - CONTROL: Online
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

    
    
    // MARK: - VEHICLE: Key Press
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

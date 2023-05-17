//
//  M_Map.swift
//  Game
//
//  Created by Quentin Beukelman on 17/05/2023.
//

import Foundation
import SceneKit

extension MapViewController {
    
    // MARK: - MAP: Read
    func readMapFile(currentTileIndex: Int) -> [[String]]? {

        guard let fileURL = Bundle.main.url(forResource: "map\(currentTileIndex)", withExtension: "txt") else {
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
    
    
    // MARK: - MAP: Update Tiles
    func updateMapTilesIfNeeded(currentMapNumber: CGFloat, vehiclePosition: SCNVector3) {
        getMapString { retrievedMapString in
            if let retrievedMapString = retrievedMapString {

                self.mapString = retrievedMapString
                print(self.mapString)
                print("Current map: \(Int(currentMapNumber))")
                
                let scene = self.scene
                for node in scene!.rootNode.childNodes {
                    if node.name != "SUN"
                        && node.name != "omni"
                        && node.name != "cube"
                        && node.name != "road"
                        && node.name != "car"
                        && node.name != "car_2"
                        && (node.presentation.worldPosition.x > (currentMapNumber + 300)
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
                
                if (Int(currentMapNumber) > self.maxMapIndex) {
                    self.maxMapIndex = Int(currentMapNumber)
                    var currentMapIndex: Int = 0
                    if (Int(currentMapNumber) > 0) {
                        currentMapIndex = Int(currentMapNumber) / 100
                    }
                    if currentMapIndex < self.mapString.count {
                        let index = self.mapString.index(self.mapString.startIndex, offsetBy: currentMapIndex + 2)
                        let currentTileIndex = self.mapString[index]
                        if (Int(currentMapNumber) == (self.maxMapIndex!)) {
                            self.placeMapTiles(mapNumber: currentMapNumber + 100, currentTileIndex: (currentTileIndex.wholeNumberValue ?? 0))
                        }
                    } else {
                        print("Invalid currentMapIndex")
                    }
                }

            } else {
                print("Failed to retrieve mapString")
            }
        }
    }
    
    
    // MARK: - MAP: Place Floor
    func addFloorToScene(mapNumber: CGFloat) -> [SCNNode] {
        var floorNodes: [SCNNode] = []

        if let floorScene = SCNScene(named: "art.scnassets/map_abstract_floor.scn"),
                let floor = floorScene.rootNode.childNode(withName: "floor", recursively: true) {
            
            let clonedFloor = floor.flattenedClone()

            clonedFloor.position = SCNVector3(x: (45 + mapNumber), y: -4.1, z: 45)
            clonedFloor.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)

            if let geometry = clonedFloor.geometry {
                clonedFloor.physicsBody = staticPhysBody(type: .static, shape: geometry, scale: SCNVector3(clonedFloor.scale.x, clonedFloor.scale.y, clonedFloor.scale.z))
            }
            floorNodes.append(clonedFloor)
        } else {
            print("Failed to load floor from scene")
        }
        
        return floorNodes
    }
    
    
    // MARK: - MAP: Place Tiles
    func placeMapTiles(mapNumber: CGFloat, currentTileIndex: Int) {
        
        print("Placing Map Tile: \(mapNumber) | map: \(currentTileIndex)")
        
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
    
    
} // End class

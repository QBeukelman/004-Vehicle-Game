//
//  M_Multiplayer.swift
//  Game
//
//  Created by Quentin Beukelman on 17/05/2023.
//

import Foundation
import SceneKit
import QuartzCore
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

extension MapViewController {
    
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
    
    // MARK: - ONLINE: Get Opp Doc
    func getOppDocument() {
        let docRef = db.collection("users").document(oppUID)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let dataOppUserName = document.data()?["firstName"] as? String {
                    self.oppUserName = dataOppUserName
                    print("Opp Name: \(self.oppUserName!)")
                    self.setOppName()
                }
            } else {
                print("Room document does not exist")
            }
        }
    }

    
    // MARK: - ONLINE: Multiplayer Observe
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
            
            queue.async(flags: .barrier) {
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
}

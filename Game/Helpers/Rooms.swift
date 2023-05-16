//
//  Rooms.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class Rooms {
    
    var roomsArray: [Room] = []
    var db: Firestore!
  
    init() {
        db = Firestore.firestore()
    }
    
    func loadData(completed: @escaping () -> ()) {
        
        db.collection("rooms").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("ERROR: adding the snapshot listener \(error!.localizedDescription)")
                return completed()
            }
            self.roomsArray = []
            // there are querySnapshot!.documents.count documents in the spots snapshot
            for document in querySnapshot!.documents {
            // You'll have to be sure you've created an initializer in the singular class (Spot, below) that accepts a dictionary.
                let room = Room(dictionary: document.data())
                room.documentID = document.documentID
                self.roomsArray.append(room)
            }
            completed()
        }
    }
} // End Rounds class

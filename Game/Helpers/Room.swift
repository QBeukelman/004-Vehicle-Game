//
//  Room.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class Room {
    
    let db = Firestore.firestore()
    
    var documentID: String
    var guestID: String
    var hostID: String
    var name: String
    var visibility: Bool
    var status: String
    var map: String
    
    var dictionary: [String: Any] {
        return ["documentID": documentID, "guestID": guestID, "hostID": guestID, "name": name, "visibility": visibility, "status": status, "map": map]
    }
    
    init(documentID: String, guestID: String, hostID: String, name: String, visibility: Bool, status: String, map: String) {
        self.documentID = documentID
        self.guestID = guestID
        self.hostID = hostID
        self.name = name
        self.visibility = visibility
        self.status = status
        self.map = map
    }
    
    convenience init () {
        self.init(documentID: "", guestID: "", hostID: "", name: "", visibility: false, status: "", map: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let documentID = dictionary["documentID"] as! String? ?? ""
        let guestID = dictionary["guestID"] as! String? ?? ""
        let hostID = dictionary["hostID"] as! String? ?? ""
        let name = dictionary["name"] as! String? ?? ""
        let visibilityValue = dictionary["visibility"]
        let visibility = (visibilityValue as? Bool) ?? false
        let status = dictionary["status"] as! String? ?? ""
        let map = dictionary["map"] as! String? ?? ""
        self.init(documentID: documentID, guestID: guestID, hostID: hostID, name: name, visibility: visibility as! Bool, status: status, map: map)
    }
}

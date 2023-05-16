//
//  AddRoomViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 26/04/2023.
//

import Foundation
import AppKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class AddRoomViewController: NSViewController {
   
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var segmentedController: NSSegmentedControl!
    @IBOutlet weak var closeWindowButton: NSButton!
    @IBOutlet weak var roomVisibilityLabel: NSTextField!
    @IBOutlet weak var roomNameField: NSTextField!
    @IBOutlet weak var createRoomButton: NSButton!
    
    var roomIsVisibility: Bool! = true
    var uid: String = ""
    var roomID: String = ""
    let db = Firestore.firestore()
    var ref: DatabaseReference!
    
    var realTimeNodeGuest: [String: Any] = [
        "w": false,
        "d": false,
        "s": false,
        "a": false,
        "posX": 0,
        "posY": 2,
        "posZ": 10,
        "rotX": 0,
        "rotY": 180,
        "rotZ": 0,
        "rotW": 0,
    ]
    
    var realTimeNodeHost: [String: Any] = [
        "w": false,
        "d": false,
        "s": false,
        "a": false,
        "posX": 0,
        "posY": 2,
        "posZ": -10,
        "rotX": 0,
        "rotY": 0,
        "rotZ": 0,
        "rotW": 0,
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpElements()
        ref = Database.database().reference()
        
    }
    
    func setUpElements() {
        errorLabel.alphaValue = 0
    }
    
    // MARK: - Map String
    func generateRandomString() -> String {
        let characters = ["0", "1", "2", "3"]
        var randomString = ""

        for _ in 0..<100 {
            let randomIndex = Int.random(in: 0..<characters.count)
            let randomCharacter = characters[randomIndex]
            randomString.append(randomCharacter)
        }

        return randomString
    }

    
    // MARK: - Create Room Doc
    func createRoomDocument() {
        let roomName = roomNameField.stringValue
        if (roomName == "") {
            errorLabel.stringValue = "Please enter a room name"
            errorLabel.alphaValue = 1
        }
        else {
            errorLabel.alphaValue = 0
            
            // Add room document
            let roomsDocumentRef = db.collection("rooms").document()
            roomID = roomsDocumentRef.documentID
            roomsDocumentRef.setData([
                "name":         roomName,
                "hostID":       uid,
                "documentID":   roomID,
                "visibility":   roomIsVisibility as Bool,
                "status":       "open",
                "guestID":      "nil",
                "map":          generateRandomString()

            ])
            createRealTimeDocument()
            // Close window
            self.performSegue(withIdentifier: "addRoomToWaitingRoom", sender: self)
        }
    }
    
    func createRealTimeDocument() {
        // Add Node to RealTime Database
        self.ref.child(roomID).child("guest").setValue(realTimeNodeGuest)
        self.ref.child(roomID).child("host").setValue(realTimeNodeHost)
        
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            roomIsVisibility = false
            roomVisibilityLabel.stringValue = "Private"
        } else {
            roomIsVisibility = true
            roomVisibilityLabel.stringValue = "Public"
        }
    }
    
    @IBAction func clowsWindowButtonTapped(_ sender: Any) {
        let parentViewController = self.presentingViewController
        parentViewController?.dismiss(self)
    }
    
    @IBAction func createRoomButtonTapped(_ sender: Any) {
        createRoomDocument()
    }
    
    
    // MARK: Override Segue
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destinationController as? WaitingRoomViewController {
            destinationVC.uid = self.uid
            destinationVC.roomID = self.roomID
        }
    }
    
} // End class







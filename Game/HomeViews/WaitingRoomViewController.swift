//
//  WaitingRoomViewController.swift
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

class WaitingRoomViewController: NSViewController {
    
    // MARK: GET ID OF ROOM
    
    @IBOutlet weak var closeWindowButton: NSButton!
    @IBOutlet weak var closeRoomButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var timeRemainingLabel: NSTextField!
    
    let db = Firestore.firestore()
    var countdownTimer: Timer!
    var totalTime = 30
    var roomID: String = ""
    var uid: String = ""
    var guestID: String = ""
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = Database.database().reference()
        print("Waiting room - UID: (\(uid) - rID: (\(roomID))")
        progressIndicator.startAnimation(nil)
        countDown()
        listenToRoomDocument()
    }
    
    
    
    func listenToRoomDocument() {
        db.collection("rooms").document(roomID)
            .addSnapshotListener { documentSnapshot, error in
              guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
              }
                if let guestID_temp = documentSnapshot? ["guestID"] as? String {
                    self.guestID = guestID_temp
                }
                if let roomStatus = documentSnapshot? ["status"] as? String {
                    if (roomStatus == "accepted") {
                        // transition to game -> send host/guest
                        self.performSegue(withIdentifier: "waitingToGame", sender: self)
                        // invalidate timer
                        self.countdownTimer.invalidate()
                        
                        // Close window
                        let parentViewController = self.presentingViewController
                        parentViewController?.dismiss(self)
                }
            }
        }
    }
    
    func countDown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.totalTime -= 1
            self.timeRemainingLabel.stringValue = "\(self.totalTime)"
            if self.totalTime <= 0 {
                self.countdownTimer.invalidate()
                self.timeRemainingLabel.stringValue = "30"
                self.progressIndicator.stopAnimation(nil)
                self.removeRoom()
            }
        }
    }
    
    func removeRoom() {
        // Remove room
        db.collection("rooms").document(roomID).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        
        // Delete RealTime node
        self.ref.child(roomID).removeValue()
        
        // Close window
        let parentViewController = self.presentingViewController
        parentViewController?.dismiss(self)
    }
    
    
    @IBAction func closeWindowButtonTapped(_ sender: Any) {
        removeRoom()
    }
    
    @IBAction func closeRoomButtonTapped(_ sender: Any) {
        removeRoom()
    }
    
    // MARK: Override Segue
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let gameVC = segue.destinationController as? MapViewController {
            gameVC.roomID = roomID
            gameVC.hostID = uid
            gameVC.guestID = guestID
            gameVC.uid = uid
        }
    }
}


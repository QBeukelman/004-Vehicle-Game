//
//  HomeViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import AppKit
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase

class HomeViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var removeRoomButton: NSButton!
    @IBOutlet weak var welcomeLabel: NSTextField!
    @IBOutlet weak var joinGameButton: NSButton!
    @IBOutlet weak var errorLabel: NSTextField!
    
    var rooms: Rooms!
    
    let db = Firestore.firestore()
    var documentID: String = ""
    var uid: String = ""
    var firstName: String = ""
    var ref: DatabaseReference!
    
    // Online
    var roomID: String = ""
    var hostID: String = ""
    var guestID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        rooms = Rooms()
        ref = Database.database().reference()
        tableView.delegate = self
        tableView.dataSource = self
        
        rooms.loadData {
            self.sortByRoomNumber()
        }
        
        manageUser()
        getUserInfo()
        
        errorLabel.alphaValue = 0
    }
    
    
    // MARK: User info
    func getUserInfo() {
        let docRef = db.collection("users").document(uid)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let userName = document.data()!["firstName"] as? String {
                    self.firstName = userName
                    self.welcomeLabel.stringValue = "Welcome, \(self.firstName)"
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func sortByRoomNumber () {
        rooms.roomsArray.sort(by: {$0.name > $1.name})
        tableView.reloadData()
    }
    
    func manageUser() {
        if (uid != "") {
            // user logged in automatically
            print("Home UID: \(uid)")
        }
    }
    
    // MARK: IB Action
    @IBAction func reomveRoomButtonTapped(_ sender: Any) {
        let selectedRow = tableView.selectedRow
        
        if selectedRow >= 0 {
            let room = rooms.roomsArray[selectedRow]
            print("Room deleted: '\(room.name)' ")
            db.collection("rooms").document(room.documentID).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Document successfully removed!")
                }
            }
            
            // Delete RealTime node
            self.ref.child(room.documentID).removeValue()
        }
    }
    
    @IBAction func joinGameButtonTapped(_ sender: Any) {
        let selectedRow = tableView.selectedRow
        
        if selectedRow >= 0 {
            let room = rooms.roomsArray[selectedRow]
            print("Joined room: '\(room.name)' ")
            errorLabel.alphaValue = 0
            roomID = room.documentID
            hostID = room.hostID
            // Update room document
            db.collection("rooms").document(roomID).setData([
                "guestID": uid,
                "status": "accepted"
            ], merge: true)
            performSegue(withIdentifier: "homeToGame", sender: self)
        } else {
            errorLabel.stringValue = "Please select or create a room"
            errorLabel.alphaValue = 1
        }
    }
    
    
    // MARK: Override Segue
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let addRoomVC = segue.destinationController as? AddRoomViewController {
            addRoomVC.uid = self.uid
        }
        if let gameVC = segue.destinationController as? MapViewController {
            gameVC.roomID = roomID
            gameVC.hostID = hostID
            gameVC.guestID = uid
            gameVC.uid = uid
        }
    }
    
} // End Class


// MARK: - Extension
extension HomeViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        let availableRooms = rooms.roomsArray.filter { $0.status == "open" }
        return availableRooms.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let room = rooms.roomsArray[row]
        let cellIdentifier = "roomsCell"
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = room.name
            
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: NSTableView, widthOfRow row: Int) -> CGFloat {
        return 200.0
    }
}

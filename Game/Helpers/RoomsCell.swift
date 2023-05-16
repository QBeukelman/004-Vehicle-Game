//
//  RoomsCell.swift
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


class RoomsTableViewCell: NSTableCellView {
    
    @IBOutlet weak var roomNameLabel: NSTextField!
    
    var room: Room! {
        didSet {
            roomNameLabel.stringValue = room.name
        }
    }
}

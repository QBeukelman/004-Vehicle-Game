//
//  Utilities.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import AppKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import StoreKit

class Utilities {
    
    static func isPasswordValid(_ password : String) -> Bool {
        
        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[a-z])(?=.*[$@$#!%*?&])[A-Za-z\\d$@$#!%*?&]{8,}")
        return passwordTest.evaluate(with: password)
    }
}

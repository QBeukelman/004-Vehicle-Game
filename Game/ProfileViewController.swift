//
//  ProfileViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 26/04/2023.
//

import Foundation
import AppKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

class ProfileViewController: NSViewController {
    
    @IBOutlet weak var logoutButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    func closeWindows() {
        for window in NSApplication.shared.windows {
            window.close()
        }
        
        let workspace = NSWorkspace.shared
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        workspace.launchApplication(withBundleIdentifier: bundleIdentifier,
                                    options: .newInstance,
                                    additionalEventParamDescriptor: nil,
                                    launchIdentifier: nil)
        NSApp.terminate(self)
    }

    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            closeWindows()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
}


//
//  AppDelegate.swift
//  Game
//
//  Created by Quentin Beukelman on 20/04/2023.
//

import Cocoa
import AppKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import FirebaseDatabase

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        FirebaseApp.configure()
        
    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed (_ theApplication: NSApplication) -> Bool {
        return true
    }
}

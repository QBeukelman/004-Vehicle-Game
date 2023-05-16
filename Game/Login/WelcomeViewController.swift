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

class WelcomeViewController: NSViewController {
    
    var db: Firestore!
    var uid: String = ""
    var documentID: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCurrentProcessorInformation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.db = Firestore.firestore()
            self.automaticLogin()
        }
        
        
    }
    
    // MARK: - Processor
    func getCurrentProcessorInformation() {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        
        var brand = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        
        let modelName = String(cString: brand)
        
        var coreCount: UInt32 = 0
        var coreCountSize = MemoryLayout<UInt32>.size
        sysctlbyname("machdep.cpu.core_count", &coreCount, &coreCountSize, nil, 0)
        
        var clockSpeed: UInt64 = 0
        var clockSpeedSize = MemoryLayout<UInt64>.size
        sysctlbyname("hw.cpufrequency", &clockSpeed, &clockSpeedSize, nil, 0)
        
        let gigahertz = Double(clockSpeed) / 1_000_000_000
        
        print("Model Name: \(modelName)")
        print("Clock Speed: \(gigahertz) GHz")
        print("Core Count: \(coreCount)")
    }
    
    
    func automaticLogin() {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            print("ERROR: no uid")
            return
        }
        let ref = self.db.collection("users");
        let documentID = ref.document(uid).documentID
        self.documentID = documentID
        self.uid = uid
        
        if uid != "" {
            // Close all windows
            for window in NSApplication.shared.windows {
                window.close()
            }
            
            self.performSegue(withIdentifier: "welcomeToHome", sender: self)
        } else {
            return
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destinationController as? HomeViewController {
            destinationVC.uid = self.uid
        }
    }
}

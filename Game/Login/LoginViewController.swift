//
//  LoginViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import AppKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

class LoginViewController: NSViewController {
    
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var closeWindowButton: NSButton!
    @IBOutlet weak var loginButton: NSButton!
    
    var uid: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setUpElements()
        userAuthListner()
    }
    
    func setUpElements() {
        errorLabel.alphaValue = 0
    }
    
    func userAuthListner() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if (user != nil) {
                self.uid = user!.uid
            }
        }
    }
    
    
    @IBAction func closeWindowButtonTapped(_ sender: Any) {
        let parentViewController = self.presentingViewController
        parentViewController?.dismiss(self)
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        // Create cleaned versions of the text field
        let email = emailTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Signing user in
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if error != nil {
                // Could not sign user in
                self.errorLabel.stringValue = error!.localizedDescription
                self.errorLabel.alphaValue = 1
            }
            
            else {
                for window in NSApplication.shared.windows {
                    window.close()
                }
                
                self.performSegue(withIdentifier: "loginToHome", sender: self)
                print ("User has signed in")
                
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destinationController as? HomeViewController {
            destinationVC.uid = self.uid
        }
    }
}

//
//  SignupViewController.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import AppKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

class SignupViewController: NSViewController {
    
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var firstNameTextField: NSTextField!
    @IBOutlet weak var lastNameTextField: NSTextField!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var closeWindowButton: NSButton!
    @IBOutlet weak var signupButton: NSButton!
    
    
    let db = Firestore.firestore()
    var uid: String = ""
    var documentID: String = ""
    var user: User!
    var activeTextField : NSTextField? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        if user == nil {
            user = User()
        }
        
        setUpElements()
        updateUserInterface()
        userAuthListner()
    }
    
    
    // MARK: - Set Up Elements
    func setUpElements() {
        errorLabel.alphaValue = 0
    }
    
    func showError(_ message:String) {
        errorLabel.stringValue = message
        errorLabel.alphaValue = 1
    }
    
    func transitionToHome() {
        for window in NSApplication.shared.windows {
            window.close()
        }
        performSegue(withIdentifier: "signupToHome", sender: self)
    }
    
    func userAuthListner() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if (user != nil) {
                self.uid = user!.uid
            }
        }
    }
    
    
    // MARK: - Update User Interface
    func updateUserInterface() {
        firstNameTextField.stringValue = user.firstName
        lastNameTextField.stringValue = user.lastName
        emailTextField.stringValue = user.email
    }
    
    
    // MARK: - Update From User Interface
    func updateFromInterface() {
        user.firstName = firstNameTextField.stringValue
        user.lastName = lastNameTextField.stringValue
        user.email = emailTextField.stringValue
    }
    
    
    // MARK: - Validate Fields
    func validateFields() -> String? {
        
        // Checking that all fields are filled in
        if firstNameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            lastNameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            emailTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all fields."
        }
        // Check if the password is secure
        let cleanedPassword = passwordTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if Utilities.isPasswordValid(cleanedPassword) == false {
            return "Please make sure your password is at least 8 characters, contains a special character, a lowercase letter and a number."
        }
        return nil
    }
    
    
    // MARK: - Buttons
    @IBAction func closeWindowButtonTapped(_ sender: Any) {
        let parentViewController = self.presentingViewController
        parentViewController?.dismiss(self)
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
      
        // Validate fields
        let error = validateFields()
        if error != nil {
            showError(error!)
        }
        
        else {
            // Create cleaned versions of the data
            let firstName = firstNameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = lastNameTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = emailTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Create user
            Auth.auth().createUser(withEmail: email, password: password) { (authResult, err) in
                
                if err != nil {
                    self.showError("Error creating user")
                    print(err)
                }
                else {
                    self.updateFromInterface()
                    self.user.saveData { (success) in
                        if success {
                            self.transitionToHome()
                        } else {
                            self.showError("Error saving user data")
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destinationController as? HomeViewController {
            destinationVC.uid = self.uid
        }
    }
    
} // End Class


// MARK: - Extension
extension SignupViewController : NSTextFieldDelegate {
  // when user select a textfield, this method will be called
  func controlTextDidBeginEditing(_ obj: Notification) {
    guard let textField = obj.object as? NSTextField else { return }
  }
  
  func controlTextDidEndEditing(_ obj: Notification) {
    guard let textField = obj.object as? NSTextField else { return }
  }
  
  // when user press return key
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if commandSelector == #selector(NSResponder.insertNewline(_:)) {
      control.window?.makeFirstResponder(nil)
      return true
    }
    return false
  }
}


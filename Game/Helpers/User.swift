//
//  User.swift
//  Game
//
//  Created by Quentin Beukelman on 25/04/2023.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth


class User {
    
    let db = Firestore.firestore()
    
    var firstName: String
    var lastName: String
    var email: String
    var documentID: String
    var uid: String
    
    var dictionary: [String: Any] {
        return ["firstName": firstName, "lastName": lastName, "email": email, "uid": uid]
    }
    
    init(firstName: String, lastName: String, email: String, documentID: String, uid: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.documentID = documentID
        self.uid = uid
    }
    
    convenience init () {
        self.init(firstName: "", lastName: "", email: "", documentID: "", uid: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let firstName = dictionary["firstName"] as! String? ?? ""
        let lastName = dictionary["lastName"] as! String? ?? ""
        let email = dictionary["email"] as! String? ?? ""
        let uid = dictionary["uid"] as! String? ?? ""
        self.init(firstName: firstName, lastName: lastName, email: email, documentID: "", uid: uid)
    }

    
    // MARK: - saveData
    func saveData(completion: @escaping (Bool) -> ()) {
        
        // Grab the user ID
        guard let uid = Auth.auth().currentUser?.uid else {
            print("ERROR: Could not save data because we don't have a valid uid.")
            return completion(false)
        }
        
        self.uid = uid
        // Create the dictionary representing user data
        let dataToSave: [String: Any] = self.dictionary
        // If no valid uid found .setData will create one.
        if self.documentID == "" { /// Create a new document via add.Document
            
            let ref1 = db.collection("users")
            self.documentID = ref1.document(uid).documentID /// Place uid in documentID
        
            // Create a new document with uid as documentID
            db.collection("users").document(documentID).setData(dataToSave){ [self] (error) in
                guard error == nil else {
                    print("ERROR: adding document) \(error!.localizedDescription)")
                    return completion(false)
                }
                print("Added document: \(self.documentID)")
                completion(true)
            }

        } else {  /// Or else save to existing documentID with .setData
            let ref2 = db.collection("users").document(self.documentID)
            ref2.setData(dataToSave) { (error) in
                guard error == nil else {
                    print("ERROR: updating document) \(error!.localizedDescription)")
                    return completion(false)
                }
                print("Updated document: \(self.documentID)")
                completion(true)
            }
        }
    }
}

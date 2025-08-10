//
//  Collaborator.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/1/25.
//

import Foundation
import FirebaseFirestore

struct Collaborator: Codable, Hashable {
    let email: String
    let displayName: String?
    let role: CollaboratorRole
    let dateAdded: Date
    
    var displayNameOrEmail: String {
        return displayName ?? email
    }
    
    init(
        email: String,
        displayName: String? = nil,
        role: CollaboratorRole,
        dateAdded: Date = Date()
    ) {
        self.email = email
        self.displayName = displayName
        self.role = role
        self.dateAdded = dateAdded
    }
    
    // MARK: - Firestore Conversion
    
    func toFirestoreDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "role": role.rawValue,
            "dateAdded": Timestamp(date: dateAdded)
        ]
        
        if let displayName = displayName {
            dict["displayName"] = displayName
        }
        
        return dict
    }
    
    static func fromFirestoreDictionary(_ data: [String: Any]) -> Collaborator? {
        guard 
            let email = data["email"] as? String,
            let roleRaw = data["role"] as? String,
            let role = CollaboratorRole(rawValue: roleRaw)
        else {
            return nil
        }
        
        let displayName = data["displayName"] as? String
        let dateAdded: Date
        
        if let timestamp = data["dateAdded"] as? Timestamp {
            dateAdded = timestamp.dateValue()
        } else {
            dateAdded = Date()
        }
        
        return Collaborator(
            email: email,
            displayName: displayName,
            role: role,
            dateAdded: dateAdded
        )
    }
}


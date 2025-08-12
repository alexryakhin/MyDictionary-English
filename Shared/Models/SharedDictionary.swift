//
//  SharedDictionary.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/10/25.
//

import Foundation
import FirebaseFirestore

struct SharedDictionary: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let owner: String
    let createdAt: Date
    
    // This will be populated separately from the collaborators subcollection
    var collaborators: [Collaborator] = []

    var userRole: CollaboratorRole? {
        guard let userEmail = AuthenticationService.shared.userEmail else { return nil }
        return collaborators.first { $0.email == userEmail }?.role
    }

    var canEdit: Bool {
        guard let userId = AuthenticationService.shared.userId else { return false }
        let userEmail = AuthenticationService.shared.userEmail
        return owner == userId || (userEmail != nil && collaborators.first { $0.email == userEmail && $0.role == .editor } != nil)
    }

    var canView: Bool {
        guard let userId = AuthenticationService.shared.userId else { return false }
        let userEmail = AuthenticationService.shared.userEmail
        return owner == userId || (userEmail != nil && collaborators.contains { $0.email == userEmail })
    }

    var isOwner: Bool {
        guard let userId = AuthenticationService.shared.userId else { return false }
        return owner == userId
    }
    
    // MARK: - Convenience Methods
    
    func getCollaboratorByEmail(email: String) -> Collaborator? {
        return collaborators.first { $0.email == email }
    }
    
    func getCollaboratorRoleByEmail(email: String) -> CollaboratorRole? {
        return getCollaboratorByEmail(email: email)?.role
    }
    
    // MARK: - Firestore Conversion
    
    func toFirestoreDictionary() -> [String: Any] {
        return [
            "name": name,
            "owner": owner,
            "createdAt": createdAt
        ]
    }
    
    static func fromFirestoreDictionary(_ data: [String: Any], id: String) -> SharedDictionary? {
        guard 
            let name = data["name"] as? String,
            let owner = data["owner"] as? String,
            let createdAtTimestamp = data["createdAt"] as? Timestamp
        else {
            return nil
        }
        
        return SharedDictionary(
            id: id,
            name: name,
            owner: owner,
            createdAt: createdAtTimestamp.dateValue()
        )
    }
}

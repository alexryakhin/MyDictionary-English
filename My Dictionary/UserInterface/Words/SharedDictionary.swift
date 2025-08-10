//
//  SharedDictionary.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/10/25.
//

import Foundation

struct SharedDictionary: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let owner: String
    let collaborators: [String: CollaboratorRole]
    let createdAt: Date

    var userRole: CollaboratorRole? {
        guard let userId = AuthenticationService.shared.userId else { return nil }
        return collaborators[userId]
    }

    var canEdit: Bool {
        guard let userId = AuthenticationService.shared.userId else { return false }
        return owner == userId || collaborators[userId] == .editor
    }

    var canView: Bool {
        guard let userId = AuthenticationService.shared.userId else { return false }
        return owner == userId || collaborators[userId] != nil
    }

    var isOwner: Bool {
        guard let userId = AuthenticationService.shared.userId else { return false }
        return owner == userId
    }
}

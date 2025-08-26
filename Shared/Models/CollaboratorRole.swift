//
//  CollaboratorRole.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/8/25.
//

enum CollaboratorRole: String, Codable {
    case owner
    case editor
    case viewer

    var displayValue: String {
        switch self {
        case .owner:
            return Loc.SharedDictionaries.CollaboratorRoles.owner
        case .editor:
            return Loc.SharedDictionaries.CollaboratorRoles.editor
        case .viewer:
            return Loc.SharedDictionaries.CollaboratorRoles.viewer
        }
    }

    static let allCases: [CollaboratorRole] = [.editor, .viewer]
}

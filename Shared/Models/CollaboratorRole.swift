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
            return Loc.CollaboratorRoles.owner.localized
        case .editor:
            return Loc.CollaboratorRoles.editor.localized
        case .viewer:
            return Loc.CollaboratorRoles.viewer.localized
        }
    }

    static let allCases: [CollaboratorRole] = [.editor, .viewer]
}

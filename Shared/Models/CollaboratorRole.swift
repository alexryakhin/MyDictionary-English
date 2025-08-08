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
            return "Owner"
        case .editor:
            return "Editor"
        case .viewer:
            return "Viewer"
        }
    }

    static let allCases: [CollaboratorRole] = [.editor, .viewer]
}

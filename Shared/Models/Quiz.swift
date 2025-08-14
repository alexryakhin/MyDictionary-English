//
//  Quiz.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

enum Quiz: String, CaseIterable, Identifiable {
    case spelling
    case chooseDefinition

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .spelling:
            return .blue
        case .chooseDefinition:
            return .accent
        }
    }

    var iconName: String {
        switch self {
        case .spelling:
            return "pencil.and.outline"
        case .chooseDefinition:
            return "list.bullet.circle"
        }
    }

    var title: String {
        switch self {
        case .spelling:
            return "Spelling Quiz"
        case .chooseDefinition:
            return "Choose Definition"
        }
    }

    var description: String {
        switch self {
        case .spelling:
            return "Test your spelling skills by typing words correctly"
        case .chooseDefinition:
            return "Select the correct definition for each word"
        }
    }
}

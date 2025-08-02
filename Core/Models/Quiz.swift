//
//  Quiz.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum Quiz: String, CaseIterable, Identifiable {
    case spelling
    case chooseDefinition

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spelling:
            return "Spelling"
        case .chooseDefinition:
            return "Choose definition"
        }
    }
}

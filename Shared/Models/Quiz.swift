//
//  Quiz.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

enum Quiz: String, CaseIterable, Identifiable {
    case spelling = "spelling"
    case chooseDefinition = "definition"

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
            return Loc.QuizTypes.spellingQuiz.localized
        case .chooseDefinition:
            return Loc.QuizTypes.chooseDefinition.localized
        }
    }

    var description: String {
        switch self {
        case .spelling:
            return Loc.QuizTypes.testSpellingSkills.localized
        case .chooseDefinition:
            return Loc.QuizTypes.selectCorrectDefinition.localized
        }
    }

    var completionDescription: String {
        switch self {
        case .spelling:
            return Loc.QuizTypes.greatJobCompletedSpellingQuiz.localized
        case .chooseDefinition:
            return Loc.QuizTypes.greatJobCompletedDefinitionQuiz.localized
        }
    }
}

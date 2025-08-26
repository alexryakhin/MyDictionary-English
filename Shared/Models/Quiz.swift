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
            return Loc.Quizzes.QuizTypes.spellingQuiz
        case .chooseDefinition:
            return Loc.Quizzes.QuizTypes.chooseDefinition
        }
    }

    var description: String {
        switch self {
        case .spelling:
            return Loc.Quizzes.QuizTypes.testSpellingSkills
        case .chooseDefinition:
            return Loc.Quizzes.QuizTypes.selectCorrectDefinition
        }
    }

    var completionDescription: String {
        switch self {
        case .spelling:
            return Loc.Quizzes.QuizTypes.greatJobCompletedSpellingQuiz
        case .chooseDefinition:
            return Loc.Quizzes.QuizTypes.greatJobCompletedDefinitionQuiz
        }
    }
}

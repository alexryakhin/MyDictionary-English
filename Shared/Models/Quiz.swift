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
    case sentenceWriting = "sentence_writing"
    case contextMultipleChoice = "context_multiple_choice"
    case fillInTheBlank = "fill_in_the_blank"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .spelling:
            return .blue
        case .chooseDefinition:
            return .accent
        case .sentenceWriting:
            return .green
        case .contextMultipleChoice:
            return .orange
        case .fillInTheBlank:
            return .purple
        }
    }

    var iconName: String {
        switch self {
        case .spelling:
            return "pencil.and.outline"
        case .chooseDefinition:
            return "list.bullet.circle"
        case .sentenceWriting:
            return "text.bubble"
        case .contextMultipleChoice:
            return "questionmark.circle"
        case .fillInTheBlank:
            return "textformat.abc"
        }
    }

    var title: String {
        switch self {
        case .spelling:
            return Loc.Quizzes.QuizTypes.spellingQuiz
        case .chooseDefinition:
            return Loc.Quizzes.QuizTypes.chooseDefinition
        case .sentenceWriting:
            return Loc.Quizzes.QuizTypes.sentenceWriting
        case .contextMultipleChoice:
            return Loc.Quizzes.QuizTypes.contextMultipleChoice
        case .fillInTheBlank:
            return Loc.Quizzes.QuizTypes.fillInTheBlank
        }
    }

    var description: String {
        switch self {
        case .spelling:
            return Loc.Quizzes.QuizTypes.testSpellingSkills
        case .chooseDefinition:
            return Loc.Quizzes.QuizTypes.selectCorrectDefinition
        case .sentenceWriting:
            return Loc.Quizzes.QuizTypes.writeSentencesWithAi
        case .contextMultipleChoice:
            return Loc.Quizzes.QuizTypes.chooseCorrectUsage
        case .fillInTheBlank:
            return Loc.Quizzes.QuizTypes.fillBlanksInContext
        }
    }

    var completionDescription: String {
        switch self {
        case .spelling:
            return Loc.Quizzes.QuizTypes.greatJobCompletedSpellingQuiz
        case .chooseDefinition:
            return Loc.Quizzes.QuizTypes.greatJobCompletedDefinitionQuiz
        case .sentenceWriting:
            return Loc.Quizzes.QuizTypes.greatJobCompletedSentenceWritingQuiz
        case .contextMultipleChoice:
            return Loc.Quizzes.QuizTypes.greatJobCompletedContextQuiz
        case .fillInTheBlank:
            return Loc.Quizzes.QuizTypes.greatJobCompletedFillInTheBlankQuiz
        }
    }

    var isOnlineQuiz: Bool {
        switch self {
        case .sentenceWriting, .contextMultipleChoice, .fillInTheBlank:
            return true
        default:
            return false
        }
    }
}

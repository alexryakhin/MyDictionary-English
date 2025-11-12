//
//  Quiz.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI

enum Quiz: String, Identifiable {
    case spelling = "spelling"
    case chooseDefinition = "definition"
    case sentenceWriting = "sentence_writing"
    case contextMultipleChoice = "context_multiple_choice"
    case fillInTheBlank = "fill_in_the_blank"
    case storyLab = "story_lab"
    case musicLesson = "music_lesson"

    static let quizCases: [Quiz] = [
        .spelling,
        .chooseDefinition,
        .sentenceWriting,
        .contextMultipleChoice,
        .fillInTheBlank
    ]

    static let discoveryLessons: [Quiz] = [
        .storyLab,
        .musicLesson
    ]

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
        case .storyLab:
            return .pink
        case .musicLesson:
            return .mint
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
        case .storyLab:
            return "books.vertical.fill"
        case .musicLesson:
            return "music.note.list"
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
        case .storyLab:
            return Loc.StoryLab.title
        case .musicLesson:
            return Loc.Quizzes.QuizTypes.musicLesson
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
        case .storyLab:
            return Loc.StoryLab.description
        case .musicLesson:
            return Loc.Quizzes.QuizTypes.musicLessonDescription
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
        case .storyLab:
            return Loc.StoryLab.completionDescription
        case .musicLesson:
            return Loc.Quizzes.QuizTypes.greatJobCompletedMusicLesson
        }
    }

    var isOnlineQuiz: Bool {
        switch self {
        case .sentenceWriting, .contextMultipleChoice, .fillInTheBlank, .storyLab, .musicLesson:
            return true
        default:
            return false
        }
    }

    var isNewQuiz: Bool {
        switch self {
        case .storyLab, .musicLesson:
            return true
        default:
            return false
        }
    }
}

//
//  QuizSession+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData
import SwiftUI

extension CDQuizSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDQuizSession> {
        return NSFetchRequest<CDQuizSession>(entityName: "QuizSession")
    }

    @NSManaged public var accuracy: Double
    @NSManaged public var correctAnswers: Int32
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var quizType: String?
    @NSManaged public var score: Int32
    @NSManaged public var totalWords: Int32
    @NSManaged public var wordsPracticed: Data?

    var quiz: Quiz? {
        Quiz(rawValue: quizType.orEmpty)
    }
}

extension CDQuizSession : Identifiable {
    var quizTitleFromType: String {
        if let quizType {
            switch quizType {
            case "sentence_writing":
                return Loc.Quizzes.QuizTypes.sentenceWriting
            case "context_multiple_choice":
                return Loc.Quizzes.QuizTypes.contextMultipleChoice
            case "fill_in_the_blank":
                return Loc.Quizzes.QuizTypes.fillInTheBlank
            case "spelling":
                return Loc.Quizzes.QuizTypes.spellingQuiz
            case "definition":
                return Loc.Quizzes.QuizTypes.chooseDefinition
            case "story_lab":
                return Loc.StoryLab.title
            case "music_lesson":
                return Loc.Quizzes.QuizTypes.musicLesson
            default:
                return quizType.capitalized
            }
        }
        return ""
    }

    var quizIconName: String {
        // First try to get the icon from the Quiz enum
        if let quiz {
            return quiz.iconName
        }

        // If that fails, try to map the quizType string to an icon
        if let quizType {
            switch quizType {
            case "sentence_writing":
                return "text.bubble"
            case "context_multiple_choice":
                return "questionmark.circle"
            case "fill_in_the_blank":
                return "textformat.abc"
            case "spelling":
                return "pencil.and.outline"
            case "definition":
                return "list.bullet.circle"
            case "story_lab":
                return "book.closed"
            case "music_lesson":
                return "music.note.list"
            default:
                return "questionmark.circle"
            }
        }

        return "questionmark.circle"
    }

    var quizColor: Color {
        // First try to get the color from the Quiz enum
        if let quiz {
            return quiz.color
        }

        // If that fails, try to map the quizType string to a color
        if let quizType {
            switch quizType {
            case "sentence_writing":
                return .green
            case "context_multiple_choice":
                return .orange
            case "fill_in_the_blank":
                return .purple
            case "spelling":
                return .blue
            case "definition":
                return .accent
            case "story_lab":
                return .pink
            case "music_lesson":
                return .mint
            default:
                return .gray
            }
        }

        return .gray
    }
}

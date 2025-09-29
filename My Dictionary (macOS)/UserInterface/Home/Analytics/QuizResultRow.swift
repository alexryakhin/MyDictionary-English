//
//  QuizResultRow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct QuizResultRow: View {
    let session: CDQuizSession

    var body: some View {
        HStack(spacing: 12) {
            // Quiz Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(quizColor.gradient)
                    .frame(width: 36, height: 36)

                Image(systemName: quizIconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(quizTitle)
                    .font(.body)
                    .fontWeight(.medium)

                Text(session.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Loc.Plurals.Analytics.pointsCount(Int(session.score)))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.accent)

                Text("\(Int(session.accuracy * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 12)
    }
    
    private var quizTitle: String {
        // First try to get the title from the Quiz enum
        if let quiz = session.quiz {
            return quiz.title
        }
        
        // If that fails, try to map the quizType string to a title
        if let quizType = session.quizType {
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
            default:
                return quizType.capitalized
            }
        }
        
        return ""
    }
    
    private var quizIconName: String {
        // First try to get the icon from the Quiz enum
        if let quiz = session.quiz {
            return quiz.iconName
        }
        
        // If that fails, try to map the quizType string to an icon
        if let quizType = session.quizType {
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
            default:
                return "questionmark.circle"
            }
        }
        
        return "questionmark.circle"
    }
    
    private var quizColor: Color {
        // First try to get the color from the Quiz enum
        if let quiz = session.quiz {
            return quiz.color
        }
        
        // If that fails, try to map the quizType string to a color
        if let quizType = session.quizType {
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
            default:
                return .gray
            }
        }
        
        return .gray
    }
}

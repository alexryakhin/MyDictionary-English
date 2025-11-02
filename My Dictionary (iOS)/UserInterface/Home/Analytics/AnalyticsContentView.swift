//
//  AnalyticsContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AnalyticsContentView: View {

    @ObservedObject var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        AnalyticsView(viewModel: viewModel)
    }
}

// MARK: - Supporting Views

struct ProgressCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(
            color.opacity(0.15),
            in: .rect(cornerRadius: 16)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(
            Color.tertiarySystemGroupedBackground,
            in: .rect(cornerRadius: 16)
        )
    }
}

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
                Text(session.quiz?.title ?? quizTitleFromType)
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
        .clippedWithBackground(
            Color.tertiarySystemGroupedBackground,
            in: .rect(cornerRadius: 16)
        )
    }
    
    // MARK: - Helper Properties
    
    private var quizTitleFromType: String {
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
            case "story_lab":
                return Loc.StoryLab.title
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
            case "story_lab":
                return "book.closed"
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
            case "story_lab":
                return .pink
            default:
                return .gray
            }
        }
        
        return .gray
    }
}

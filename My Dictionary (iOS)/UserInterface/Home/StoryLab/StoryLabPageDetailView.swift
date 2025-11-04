//
//  StoryLabPageDetailView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct StoryLabPageDetailView: View {
    let page: AIStoryPage
    let pageIndex: Int
    let session: StorySession
    let story: AIStoryResponse
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Page Header
                Text(Loc.StoryLab.Reading.page(pageIndex + 1, story.pages.count))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 16)

                // Story Text
                storyTextSection

                // Quiz Questions
                quizSection
            }
            .padding(16)
        }
        .groupedBackground()
        .navigation(
            title: story.title,
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    dismiss()
                }
            }
        )
    }
    
    // MARK: - Story Text Section
    
    private var storyTextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Loc.StoryLab.Reading.title)
                .font(.headline)
            
            Text(page.storyText)
                .textSelection(.enabled)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Quiz Section
    
    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Loc.StoryLab.Quiz.title)
                .font(.headline)
            
            ForEach(Array(page.questions.enumerated()), id: \.offset) { questionIndex, question in
                questionDetailView(question: question, questionIndex: questionIndex)
            }
        }
    }
    
    private func questionDetailView(question: AIComprehensionQuestion, questionIndex: Int) -> some View {
        let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: questionIndex)
        let userAnswerIndex = session.answers[key]
        let isCorrect = userAnswerIndex != nil && userAnswerIndex! < question.options.count && question.options[userAnswerIndex!].isCorrect
        
        return VStack(alignment: .leading, spacing: 12) {
            // Question
            Text(question.question)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Options
            ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                let isSelected = userAnswerIndex == optionIndex
                let isCorrectOption = option.isCorrect
                
                HStack(spacing: 12) {
                    // Answer indicator
                    if isSelected || isCorrectOption {
                        Image(systemName: isCorrectOption ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(isCorrectOption ? .green : .red)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(option.text)
                        .font(.body)
                        .foregroundStyle(
                            isCorrectOption ? .green :
                            isSelected && !isCorrect ? .red :
                            .primary
                        )
                        
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            
            // Explanation
            if let explanation = question.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

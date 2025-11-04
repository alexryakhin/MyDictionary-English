//
//  StoryLabQuizView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct StoryLabQuizView: View {
    let page: AIStoryPage
    let pageIndex: Int
    @ObservedObject var viewModel: StoryLabViewModel
    
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswerIndex: Int?
    @State private var showFeedback: Bool = false
    
    var currentQuestion: AIComprehensionQuestion {
        page.questions[currentQuestionIndex]
    }
    
    var isQuestionAnswered: Bool {
        guard let session = viewModel.session else { return false }
        let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: currentQuestionIndex)
        return session.answers[key] != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quiz Header
            quizHeader
            
            // Questions
            questionSection
            
            // Navigation
            questionNavigation
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
        .id(pageIndex) // Force view recreation when page changes
        .onChange(of: pageIndex) {
            // Reset state when page changes
            currentQuestionIndex = 0
            selectedAnswerIndex = nil
            showFeedback = false
        }
        .onAppear {
            // Reset to first question and load any existing answer for this question
            currentQuestionIndex = 0
            selectedAnswerIndex = nil
            showFeedback = false
            
            // Load previously selected answer if exists for first question
            if let session = viewModel.session {
                let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: 0)
                if let previousAnswer = session.answers[key] {
                    selectedAnswerIndex = previousAnswer
                    showFeedback = true
                }
            }
        }
    }
    
    // MARK: - Quiz Header
    
    private var quizHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Loc.StoryLab.Quiz.title)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(Loc.StoryLab.Quiz.pageQuestions(pageIndex + 1))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("\(Loc.Quizzes.progress): \(currentQuestionIndex + 1) / \(page.questions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Text
            Text(currentQuestion.question)
                .font(.body)
                .fontWeight(.medium)
                .padding(.bottom, 8)
            
            // Answer Options
            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                answerOptionButton(index: index, option: option)
            }
            
            // Feedback
            if showFeedback {
                feedbackView
            }
        }
    }
    
    // MARK: - Answer Option Button
    
    @ViewBuilder
    private func answerOptionButton(index: Int, option: AIComprehensionOption) -> some View {
        if let session = viewModel.session {
            let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: currentQuestionIndex)
            let isSelected = selectedAnswerIndex == index || session.answers[key] == index
            let isCorrect = option.isCorrect
            let isWrong = isSelected && !isCorrect
            
            Button {
            if !isQuestionAnswered {
                selectedAnswerIndex = index
                submitAnswer()
            }
        } label: {
            HStack {
                Text(option.text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isQuestionAnswered {
                    if isCorrect && isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if isWrong {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    } else if isCorrect {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                } else {
                    Image(systemName: isSelected ? "circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .accent : .secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isWrong ? Color.red.opacity(0.1) :
                        (isCorrect && isSelected) ? Color.green.opacity(0.1) :
                        (isSelected && !isQuestionAnswered) ? Color.accent.opacity(0.1) :
                        Color.tertiarySystemGroupedBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isWrong ? Color.red :
                        (isCorrect && isSelected) ? Color.green :
                        (isSelected && !isQuestionAnswered) ? Color.accent :
                        Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            }
            .buttonStyle(.plain)
            .disabled(isQuestionAnswered && selectedAnswerIndex != index)
        }
    }
    
    // MARK: - Feedback View
    
    private var feedbackView: some View {
        let isCorrect = selectedAnswerIndex != nil && selectedAnswerIndex! < currentQuestion.options.count && currentQuestion.options[selectedAnswerIndex!].isCorrect
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
                
                Text(isCorrect ? Loc.StoryLab.Quiz.correct : Loc.StoryLab.Quiz.incorrect)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isCorrect ? .green : .red)
            }
            
            // Show explanation if available
            if let explanation = currentQuestion.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
    
    // MARK: - Question Navigation
    
    private var questionNavigation: some View {
        HStack(spacing: 16) {
            HeaderButton(Loc.Actions.back) {
                if currentQuestionIndex > 0 {
                    currentQuestionIndex -= 1
                    selectedAnswerIndex = nil
                    showFeedback = false
                }
            }
            .disabled(currentQuestionIndex == 0)
            
            Spacer()
            
            if currentQuestionIndex < page.questions.count - 1 {
                HeaderButton(Loc.StoryLab.Quiz.nextQuestion, style: .borderedProminent) {
                    nextQuestion()
                }
                .disabled(!isQuestionAnswered)
            }
        }
    }
    
    // MARK: - Actions
    
    private func submitAnswer() {
        guard let selectedAnswerIndex, let session = viewModel.session else { return }

        let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: currentQuestionIndex)
        
        // Only submit if not already answered
        if session.answers[key] == nil {
            viewModel.handle(.submitAnswer(
                pageIndex: pageIndex,
                questionIndex: currentQuestionIndex,
                answerIndex: selectedAnswerIndex
            ))
            showFeedback = true
            
        // Session is automatically updated via viewModel
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < page.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            showFeedback = false
            
            // Load previously selected answer if exists
            if let session = viewModel.session {
                let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: currentQuestionIndex)
                if let previousAnswer = session.answers[key] {
                    selectedAnswerIndex = previousAnswer
                    showFeedback = true
                }
            }
        }
    }
}

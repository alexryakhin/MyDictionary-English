//
//  MusicQuizView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct MusicQuizView: View {
    let quiz: AIComprehensionQuiz
    @ObservedObject var viewModel: MusicDiscoveringViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswerIndex: Int?
    @State private var showFeedback: Bool = false
    @State private var answers: [Int: Int] = [:]
    
    var currentQuestion: AIComprehensionQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    var isQuestionAnswered: Bool {
        answers[currentQuestionIndex] != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Progress indicator
                    progressIndicator
                    
                    // Question
                    questionSection
                    
                    // Navigation
                    questionNavigation
                }
                .padding()
            }
            .groupedBackground()
            .navigation(
                title: "Song Quiz",
                mode: .inline,
                trailingContent: {
                    HeaderButton(Loc.Actions.done) {
                        dismiss()
                    }
                }
            )
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quiz.questions.count))
                .progressViewStyle(.linear)
            
            Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(currentQuestion.question)
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                answerButton(option: option, index: index)
            }
            
            // Show feedback if answered
            if let selectedIndex = selectedAnswerIndex,
               selectedIndex < currentQuestion.options.count,
               showFeedback {
                let selectedOption = currentQuestion.options[selectedIndex]
                let isCorrect = selectedOption.isCorrect
                
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                    
                    if let explanation = currentQuestion.explanation {
                        Text(explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
    
    private func answerButton(option: AIComprehensionOption, index: Int) -> some View {
        let isSelected = selectedAnswerIndex == index
        let isCorrect = option.isCorrect
        
        return Button(action: {
            if !isQuestionAnswered {
                selectedAnswerIndex = index
                answers[currentQuestionIndex] = index
                showFeedback = true
                
                // Submit answer to session
                if var session = viewModel.currentSession {
                    session.submitQuizAnswer(
                        questionIndex: currentQuestionIndex,
                        answerIndex: index,
                        isCorrect: isCorrect
                    )
                    viewModel.updateCurrentSession(session)
                }
                
                HapticManager.shared.triggerImpact(style: isCorrect ? .medium : .light)
            }
        }) {
            HStack {
                Text(option.text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(
                        isSelected
                            ? (isCorrect ? .white : .white)
                            : .primary
                    )
                
                Spacer()
                
                if isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isSelected ? .white : nil)
                }
            }
            .padding()
            .background(
                isSelected
                    ? (isCorrect ? Color.green : Color.red)
                    : Color.secondarySystemGroupedBackground
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isQuestionAnswered)
    }
    
    // MARK: - Question Navigation
    
    private var questionNavigation: some View {
        HStack {
            Button(action: {
                if currentQuestionIndex > 0 {
                    withAnimation {
                        currentQuestionIndex -= 1
                        selectedAnswerIndex = answers[currentQuestionIndex]
                        showFeedback = answers[currentQuestionIndex] != nil
                    }
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .padding()
                .background(Color.secondarySystemGroupedBackground)
                .cornerRadius(8)
            }
            .disabled(currentQuestionIndex == 0)
            
            Spacer()
            
            Button(action: {
                if currentQuestionIndex < quiz.questions.count - 1 {
                    withAnimation {
                        currentQuestionIndex += 1
                        selectedAnswerIndex = answers[currentQuestionIndex]
                        showFeedback = answers[currentQuestionIndex] != nil
                    }
                } else {
                    // Quiz completed
                    if var session = viewModel.currentSession {
                        session.markQuizComplete()
                        viewModel.updateCurrentSession(session)
                    }
                    dismiss()
                }
            }) {
                HStack {
                    Text(currentQuestionIndex < quiz.questions.count - 1 ? "Next" : "Finish")
                    Image(systemName: "chevron.right")
                }
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    MusicQuizView(
        quiz: AIComprehensionQuiz(
            questions: [
                AIComprehensionQuestion(
                    question: "What does 'carnaval' mean in this context?",
                    options: [
                        AIComprehensionOption(text: "A celebration", isCorrect: true),
                        AIComprehensionOption(text: "A sad event", isCorrect: false),
                        AIComprehensionOption(text: "A serious matter", isCorrect: false),
                        AIComprehensionOption(text: "A problem", isCorrect: false)
                    ],
                    explanation: "Carnaval refers to a festive celebration with music and dancing."
                )
            ],
            difficulty: "B1"
        ),
        viewModel: MusicDiscoveringViewModel()
    )
}


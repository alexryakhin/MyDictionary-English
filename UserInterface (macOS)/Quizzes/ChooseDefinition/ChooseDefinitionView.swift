import SwiftUI

struct ChooseDefinitionView: View {

    typealias ViewModel = ChooseDefinitionViewModel

    @StateObject private var viewModel: ChooseDefinitionViewModel
    @Environment(\.dismiss) private var dismiss

    init(wordCount: Int) {
        self._viewModel = StateObject(wrappedValue: ChooseDefinitionViewModel(
            wordsProvider: ServiceManager.shared.wordsProvider,
            wordCount: wordCount
        ))
    }

    var body: some View {
        if !viewModel.isQuizComplete {
            VStack(spacing: 0) {
                // Header with progress
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Word Card
                        wordCard
                        
                        // Answer Options
                        answerOptionsSection
                        
                        // Action Buttons
                        actionButtons
                    }
                    .padding(24)
                }
            }
            .background(Color(.windowBackgroundColor))
            .navigationTitle("Choose Definition Quiz")
            .onAppear {
                AnalyticsService.shared.logEvent(.definitionQuizOpened)
            }
        } else {
            // Completion View
            completionView
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            // Progress Bar
            ProgressView(value: Double(viewModel.correctAnswers), total: Double(viewModel.totalQuestions))
                .progressViewStyle(.linear)
                .padding(.horizontal, 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress: \(viewModel.correctAnswers)/\(viewModel.totalQuestions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if viewModel.currentStreak > 0 {
                        Text("🔥 Streak: \(viewModel.currentStreak)")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Score: \(viewModel.score)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text("Best: \(viewModel.bestStreak)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.windowBackgroundColor))
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Word")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    viewModel.handle(.playWord)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.currentQuestion?.wordItself ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                
                if let partOfSpeech = viewModel.currentQuestion?.partOfSpeech, !partOfSpeech.isEmpty {
                    Text(partOfSpeech)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var answerOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Choose the correct definition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.answerOptions.enumerated()), id: \.element.id) { index, word in
                    AnswerOptionButton(
                        definition: word.definition ?? "",
                        isSelected: viewModel.selectedAnswerIndex == index,
                        isCorrect: viewModel.isShowingAnswerFeedback && index == viewModel.correctAnswerIndex,
                        isIncorrect: viewModel.isShowingAnswerFeedback && viewModel.selectedAnswerIndex == index && !viewModel.isCorrectAnswer
                    ) {
                        if !viewModel.isShowingAnswerFeedback {
                            viewModel.handle(.selectAnswer(index))
                        }
                    }
                }
            }
            
            if viewModel.isShowingAnswerFeedback {
                HStack {
                    Image(systemName: viewModel.isCorrectAnswer ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(viewModel.isCorrectAnswer ? .green : .red)
                    
                    Text(viewModel.answerFeedback)
                        .font(.caption)
                        .foregroundColor(viewModel.isCorrectAnswer ? .green : .red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(viewModel.isCorrectAnswer ? .green.opacity(0.1) : .red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.handle(.skipWord)
            } label: {
                Label("Skip Word (-25 points)", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.bordered)
            .disabled(viewModel.isShowingAnswerFeedback)
        }
    }

    private var completionView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(.green.gradient)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Great job! You've completed the choose definition quiz.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Score Card
                VStack(spacing: 16) {
                    Text("Your Results")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Final Score")
                            Spacer()
                            Text("\(viewModel.score)")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Correct Answers")
                            Spacer()
                            Text("\(viewModel.correctAnswers)/\(viewModel.totalQuestions)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Best Streak")
                            Spacer()
                            Text("\(viewModel.bestStreak)")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Accuracy")
                            Spacer()
                            Text("\(Int((Double(viewModel.correctAnswers) / Double(viewModel.totalQuestions)) * 100))%")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    .font(.body)
                }
                .padding(24)
                .background(Color(.secondarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Restart Quiz") {
                        viewModel.handle(.restartQuiz)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            
            Spacer()
        }
        .background(Color(.windowBackgroundColor))
    }
}

struct AnswerOptionButton: View {
    let definition: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(definition)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(foregroundColor)
                
                Spacer()
                
                if isSelected || isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .green : .red)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isSelected || isCorrect || isIncorrect)
    }
    
    private var backgroundColor: Color {
        if isCorrect {
            return .green.opacity(0.1)
        } else if isIncorrect {
            return .red.opacity(0.1)
        } else if isSelected {
            return .blue.opacity(0.1)
        } else {
            return Color(.tertiarySystemFill)
        }
    }
    
    private var foregroundColor: Color {
        if isCorrect || isIncorrect {
            return .primary
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isIncorrect {
            return .red
        } else if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
}

#Preview {
    ChooseDefinitionView(wordCount: 10)
}

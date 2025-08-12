import SwiftUI

struct ChooseDefinitionQuizContentView: View {

    @StateObject private var viewModel: ChooseDefinitionQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(wordCount: Int, hardWordsOnly: Bool = false) {
        self._viewModel = StateObject(wrappedValue: ChooseDefinitionQuizViewModel(
            wordCount: wordCount,
            hardWordsOnly: hardWordsOnly
        ))
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if let errorMessage = viewModel.errorMessage {
                // Error state
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.gradient)
                        
                        Text("Quiz Unavailable")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)
                    
                    Button {
                        dismiss()
                    } label: {
                        Label("Back to Quizzes", systemImage: "chevron.left")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.accent.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else if viewModel.words.isNotEmpty {
                if !viewModel.isQuizComplete {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Word Card
                            wordCard

                            // Options Section
                            optionsSection

                            // Action Buttons
                            actionButtons
                        }
                        .padding(.horizontal, 16)
                    }
                } else {
                    // Completion View
                    completionView
                        .if(isPad) { view in
                            view.frame(maxWidth: 500, alignment: .center)
                        }
                }
            }
        }
        .navigation(
            title: "Definition Quiz",
            mode: .inline,
            trailingContent: {
                HeaderButton("Exit") {
                    viewModel.handle(.saveSession)
                    dismiss()
                }
            },
            bottomContent: { headerView }
        )
        .onAppear {
            AnalyticsService.shared.logEvent(.definitionQuizOpened)
        }
        .onDisappear {
            // Handle early exit - save current progress if quiz is in progress
            if !viewModel.isQuizComplete && viewModel.wordsPlayed.count > 0 {
                viewModel.handle(.saveSession)
            }
        }
        .onReceive(viewModel.dismissPublisher) {
            dismiss()
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            // Progress Bar
            ProgressView(value: Double(viewModel.questionsAnswered), total: Double(viewModel.wordCount))
                .progressViewStyle(.linear)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress: \(viewModel.questionsAnswered)/\(viewModel.wordCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if viewModel.currentStreak > 0 {
                        Text("🔥 Streak: \(viewModel.currentStreak)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Score: \(viewModel.score)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                    
                    Text("Best: \(viewModel.bestStreak)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                Text("Word")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(viewModel.correctWord.quiz_wordItself)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            Text(viewModel.correctWord.quiz_partOfSpeech)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green.opacity(0.2))
                .foregroundStyle(.green)
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .clippedWithBackground()
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.circle")
                    .font(.title2)
                    .foregroundStyle(.accent)
                
                Text("Choose the Correct Definition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(0..<3) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.handle(.answerSelected(index))
                        }
                    } label: {
                        HStack {
                            Text(viewModel.words[index].quiz_definition)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .clippedWithPaddingAndBackground(backgroundColor(for: index), cornerRadius: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor(for: index), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.answerFeedback != .none)
                }
            }
            
            if case .incorrect = viewModel.answerFeedback {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    
                    Text("Incorrect! Moving to next question...")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .background(.red.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .clippedWithBackground(Color(.secondarySystemGroupedBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.handle(.skipWord)
                }
            } label: {
                Label("Skip Word (-2 points)", systemImage: "arrow.right.circle")
                    .padding(8)
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.bordered)
        }
    }

    private var completionView: some View {
        VStack(spacing: 32) {
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
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Great job! You've completed the definition quiz.")
                        .font(.body)
                        .foregroundStyle(.secondary)
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
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Text("Correct Answers")
                            Spacer()
                            Text("\(viewModel.correctAnswers)/\(viewModel.wordsPlayed.count)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Best Streak")
                            Spacer()
                            Text("\(viewModel.bestStreak)")
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                        
                        HStack {
                            Text("Accuracy")
                            Spacer()
                            Text("\(Int((Double(viewModel.correctAnswers) / Double(viewModel.wordsPlayed.count)) * 100))%")
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                    }
                    .font(.body)
                }
                .padding(24)
                .clippedWithBackground()
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button {
                    viewModel.handle(.restartQuiz)
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    dismiss()
                } label: {
                    Label("Back to Quizzes", systemImage: "chevron.left")
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .groupedBackground()
    }

    private func backgroundColor(for index: Int) -> Color {
        switch viewModel.answerFeedback {
        case .none:
            return Color(.tertiarySystemGroupedBackground)
        case .correct(let correctIndex):
            return index == correctIndex ? Color.green.opacity(0.2) : Color(.tertiarySystemGroupedBackground)
        case .incorrect(let incorrectIndex):
            return index == incorrectIndex ? Color.red.opacity(0.2) : Color(.tertiarySystemGroupedBackground)
        }
    }

    private func borderColor(for index: Int) -> Color {
        switch viewModel.answerFeedback {
        case .none:
            return Color(.clear)
        case .correct(let correctIndex):
            return index == correctIndex ? Color.green : Color(.clear)
        case .incorrect(let incorrectIndex):
            return index == incorrectIndex ? Color.red : Color(.clear)
        }
    }
}

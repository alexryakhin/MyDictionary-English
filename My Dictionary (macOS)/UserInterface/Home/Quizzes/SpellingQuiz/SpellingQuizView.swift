import SwiftUI

struct SpellingQuizView: View {

    @StateObject private var viewModel: SpellingQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: SpellingQuizViewModel(
            preset: preset
        ))
    }

    var body: some View {
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
                
                ActionButton(
                    "Back to Quizzes",
                    systemImage: "chevron.left",
                    style: .borderedProminent
                ) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .groupedBackground()
            .onReceive(viewModel.dismissPublisher) {
                dismiss()
            }
        } else if !viewModel.isQuizComplete {
            ScrollView {
                VStack(spacing: 12) {
                    // Definition Card
                    definitionCard

                    // Answer Section
                    answerSection

                    // Action Buttons
                    actionButtons
                }
                .padding(12)
            }
            .groupedBackground()
            .navigationTitle("Spelling Quiz")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Exit button
                    Button("Exit") {
                        viewModel.handle(.dismiss)
                    }
                    .help("Exit Quiz")
                }
            }
            .safeAreaInset(edge: .bottom) {
                headerView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.bar)
            }
            .onAppear {
                AnalyticsService.shared.logEvent(.spellingQuizOpened)
            }
            .onDisappear {
                // Handle early exit - save current progress if quiz is in progress
                if !viewModel.isQuizComplete && viewModel.wordsPlayed.count > 0 {
                    viewModel.handle(.dismiss)
                }
            }
            .onReceive(viewModel.dismissPublisher) {
                dismiss()
            }
        } else {
            // Completion View
            completionView
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            // Progress Bar
            ProgressView(value: Double(viewModel.wordsPlayed.count), total: Double(viewModel.totalQuestions))
                .progressViewStyle(.linear)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress: \(viewModel.wordsPlayed.count)/\(viewModel.totalQuestions)")
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
                        .foregroundStyle(.blue)
                    
                    Text("Best: \(viewModel.bestStreak)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var definitionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("Definition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(viewModel.randomWord?.quiz_definition ?? "")
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            if let partOfSpeech = viewModel.randomWord?.quiz_partOfSpeech, !partOfSpeech.isEmpty {
                TagView(text: partOfSpeech, color: .blue, size: .small, style: .regular)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Hint section
            if viewModel.isShowingHint, let randomWord = viewModel.randomWord {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    
                    Text("Hint: The word starts with '\(randomWord.quiz_wordItself.prefix(1).uppercased())'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.title2)
                    .foregroundStyle(.accent)

                Text("Your Answer")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.attemptCount > 0 {
                    Text("Attempt \(viewModel.attemptCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            TextField("Type the word here...", text: $viewModel.answerTextField, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(vertical: 8, horizontal: 12)
                .background(Color.tertiarySystemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(viewModel.isShowingCorrectAnswer || viewModel.attemptCount >= 3)
                .onSubmit {
                    if !viewModel.isShowingCorrectAnswer && viewModel.attemptCount < 3 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.handle(.confirmAnswer)
                        }
                    }
                }
            
            if viewModel.isShowingCorrectAnswer {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.accent)

                    Text(["Correct!", "Well done!", "Keep up the good work!"].randomElement() ?? "Correct!")
                        .font(.caption)
                        .foregroundStyle(.accent)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.accent.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if viewModel.attemptCount >= 3 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    
                    Text("The correct word is '\(viewModel.randomWord?.quiz_wordItself ?? "")'. Moving to next word...")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.red.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if !viewModel.isCorrectAnswer && viewModel.attemptCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    
                    Text(incorrectMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isMovingOnToNextWord = viewModel.isShowingCorrectAnswer || viewModel.attemptCount >= 3
        VStack(spacing: 12) {
            ActionButton(
                isMovingOnToNextWord ? "Next Word" : "Submit Answer",
                systemImage: isMovingOnToNextWord ? "arrow.right.circle.fill" : "checkmark.circle.fill",
                style: .borderedProminent
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isMovingOnToNextWord {
                        viewModel.handle(.nextWord)
                    } else {
                        viewModel.handle(.confirmAnswer)
                    }
                }
            }
            .disabled(viewModel.answerTextField.isEmpty)

            ActionButton("Skip Word (-2 points)", systemImage: "arrow.right.circle") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.handle(.skipWord)
                }
            }
            .disabled(isMovingOnToNextWord)
        }
    }

    private var completionView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(.accent.gradient)
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
                    
                    Text("Great job! You've completed the spelling quiz.")
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
                                .foregroundStyle(.blue)
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
                            Text("\(Int(calculateAccuracy()))%")
                                .fontWeight(.medium)
                                .foregroundStyle(.accent)
                        }
                        
                        #if DEBUG
                        if viewModel.wordsPlayed.count > 0 {
                            HStack {
                                Text("Debug")
                                Spacer()
                                Text("contributions: \(viewModel.accuracyContributions.values.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        #endif
                    }
                    .font(.body)
                }
                .padding(24)
                .background(Color.secondarySystemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                ActionButton("Try Again", systemImage: "arrow.clockwise", style: .borderedProminent) {
                    viewModel.handle(.restartQuiz)
                }
                ActionButton("Back to Quizzes", systemImage: "chevron.left") {
                    dismiss()
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
        .groupedBackground()
        .onReceive(viewModel.dismissPublisher) {
            dismiss()
        }
    }

    private var incorrectMessage: String {
        guard let randomWord = viewModel.randomWord else { return "" }

        if viewModel.attemptCount > 2 {
            return "Your word is '\(randomWord.quiz_wordItself.trimmed)'. Try harder :)"
        } else {
            return "Incorrect. Try again"
        }
    }

    private func calculateAccuracy() -> Double {
        let wordsPlayedCount = Double(viewModel.wordsPlayed.count)
        
        if wordsPlayedCount == 0 {
            return 0.0
        }
        
        // Calculate accuracy based on contributions
        let totalAccuracyContribution = viewModel.accuracyContributions.values.reduce(0, +)
        let averageAccuracy = totalAccuracyContribution / wordsPlayedCount
        return averageAccuracy * 100
    }
}

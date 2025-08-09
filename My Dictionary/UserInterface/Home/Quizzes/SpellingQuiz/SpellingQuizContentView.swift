import SwiftUI

struct SpellingQuizContentView: View {

    @StateObject private var viewModel: SpellingQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(wordCount: Int, hardWordsOnly: Bool = false) {
        self._viewModel = StateObject(wrappedValue: SpellingQuizViewModel(
            wordCount: wordCount,
            hardWordsOnly: hardWordsOnly
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
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .onReceive(viewModel.dismissPublisher) {
                dismiss()
            }
        } else if !viewModel.isQuizComplete {
            ScrollView {
                VStack(spacing: 24) {
                    // Definition Card
                    definitionCard

                    // Answer Section
                    answerSection

                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigation(
                title: "Spelling Quiz",
                mode: .inline,
                trailingContent: {
                    HeaderButton(text: "Exit") {
                        viewModel.handle(.dismiss)
                    }
                },
                bottomContent: {
                    headerView
                }
            )
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
                    Text("Progress: \(viewModel.wordsPlayed.count + 1)/\(viewModel.totalQuestions)")
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
        }
    }

    private var definitionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Definition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(viewModel.randomWord?.definition ?? "")
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
            if let partOfSpeech = viewModel.randomWord?.partOfSpeech, !partOfSpeech.isEmpty {
                HStack {
                    Text(partOfSpeech)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            
            // Hint section
            if viewModel.isShowingHint, let randomWord = viewModel.randomWord {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Hint: The word starts with '\(randomWord.wordItself?.prefix(1).uppercased() ?? "")'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Your Answer")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.attemptCount > 0 {
                    Text("Attempt \(viewModel.attemptCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            TextField("Type the word here...", text: $viewModel.answerTextField, axis: .vertical)
                .padding(vertical: 8, horizontal: 12)
                .background(Color(.tertiarySystemGroupedBackground))
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
                        .foregroundColor(.green)
                    
                    Text(["Correct!", "Well done!", "Keep up the good work!"].randomElement() ?? "Correct!")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.green.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if viewModel.attemptCount >= 3 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text("The correct word is '\(viewModel.randomWord?.wordItself ?? "")'. Moving to next word...")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.red.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if !viewModel.isCorrectAnswer && viewModel.attemptCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(incorrectMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if viewModel.isShowingCorrectAnswer || viewModel.attemptCount >= 3 {
                        viewModel.handle(.nextWord)
                    } else {
                        viewModel.handle(.confirmAnswer)
                    }
                }
            } label: {
                if viewModel.isShowingCorrectAnswer || viewModel.attemptCount >= 3 {
                    Label("Next Word", systemImage: "arrow.right.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                } else {
                    Label("Submit Answer", systemImage: "checkmark.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.answerTextField.isEmpty)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.handle(.skipWord)
                }
            } label: {
                Label("Skip Word (-25 points)", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.bordered)
            .disabled(viewModel.isShowingCorrectAnswer || viewModel.attemptCount >= 3)
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
                    
                    Text("Great job! You've completed the spelling quiz.")
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
                            Text("\(viewModel.correctAnswers)/\(viewModel.wordsPlayed.count)")
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
                            Text("\(Int(calculateAccuracy()))%")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        // Debug info (can be removed later)
                        if viewModel.wordsPlayed.count > 0 {
                            HStack {
                                Text("Debug")
                                Spacer()
                                Text("contributions: \(viewModel.accuracyContributions.values.map { String(format: "%.2f", $0) }.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .font(.body)
                }
                .padding(24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.handle(.restartQuiz)
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    dismiss()
                } label: {
                    Label("Back to Quizzes", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .foregroundStyle(.secondary)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
        .onReceive(viewModel.dismissPublisher) {
            dismiss()
        }
    }

    private var incorrectMessage: String {
        guard let randomWord = viewModel.randomWord else { return "" }

        if viewModel.attemptCount > 2 {
            return "Your word is '\(randomWord.wordItself?.trimmed ?? "")'. Try harder :)"
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

import SwiftUI

struct SpellingQuizContentView: View {

    @StateObject private var viewModel: SpellingQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(wordCount: Int) {
        self._viewModel = StateObject(wrappedValue: SpellingQuizViewModel(
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
                        // Definition Card
                        definitionCard
                        
                        // Answer Section
                        answerSection
                        
                        // Action Buttons
                        actionButtons
                    }
                    .padding(24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Spelling Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AnalyticsService.shared.logEvent(.spellingQuizOpened)
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
        .background(Color(.systemGroupedBackground))
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) {
            Divider()
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
                        .background(.blue.opacity(0.1))
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
                .background(.yellow.opacity(0.1))
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
                .background(.green.opacity(0.1))
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
                .background(.red.opacity(0.1))
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
                .background(.orange.opacity(0.1))
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
                    if viewModel.isShowingCorrectAnswer {
                        viewModel.handle(.nextWord)
                    } else if viewModel.attemptCount >= 3 {
                        viewModel.handle(.skipWord)
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
    }

    private var incorrectMessage: String {
        guard let randomWord = viewModel.randomWord else { return "" }

        if viewModel.attemptCount > 2 {
            return "Your word is '\(randomWord.wordItself?.trimmed ?? "")'. Try harder :)"
        } else {
            return "Incorrect. Try again"
        }
    }
}

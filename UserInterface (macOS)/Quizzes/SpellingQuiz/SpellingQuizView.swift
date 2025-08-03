import SwiftUI

struct SpellingQuizView: View {

    typealias ViewModel = SpellingQuizViewModel

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
            .background(Color(.windowBackgroundColor))
            .navigationTitle("Spelling Quiz")
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
            ProgressView(value: Double(viewModel.questionsAnswered), total: Double(viewModel.totalQuestions))
                .progressViewStyle(.linear)
                .padding(.horizontal, 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress: \(viewModel.questionsAnswered)/\(viewModel.totalQuestions)")
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
            .padding(.horizontal, 24)
        }
        .background(Color(.windowBackgroundColor))
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
                    .foregroundStyle(.blue)
                
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
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            
            // Hint section
            if viewModel.isShowingHint, let randomWord = viewModel.randomWord {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    
                    Text("Hint: The word starts with '\(randomWord.wordItself?.prefix(1).uppercased() ?? "")'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.title2)
                    .foregroundStyle(.green)
                
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
                .padding(vertical: 8, horizontal: 12)
                .background(Color(.tertiarySystemFill))
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
                        .foregroundStyle(.green)
                    
                    Text(["Correct!", "Well done!", "Keep up the good work!"].randomElement() ?? "Correct!")
                        .font(.caption)
                        .foregroundStyle(.green)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if viewModel.attemptCount >= 3 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    
                    Text("The correct word is '\(viewModel.randomWord?.wordItself ?? "")'. Moving to next word...")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if !viewModel.isCorrectAnswer && viewModel.attemptCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    
                    Text("Try again")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
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
                            Text("\(viewModel.correctAnswers)/\(viewModel.totalQuestions)")
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
                            Text("\(Int((Double(viewModel.correctAnswers) / Double(viewModel.totalQuestions)) * 100))%")
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
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

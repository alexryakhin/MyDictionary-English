import SwiftUI

struct ChooseDefinitionQuizContentView: View {

    @StateObject private var viewModel = ChooseDefinitionQuizViewModel(
        wordsProvider: ServiceManager.shared.wordsProvider
    )
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.words.isNotEmpty {
                if !viewModel.isQuizComplete {
                    VStack(spacing: 0) {
                        // Header with progress
                        headerView

                        ScrollView {
                            VStack(spacing: 16) {
                                // Word Card
                                wordCard

                                // Options Section
                                optionsSection

                                // Action Buttons
                                actionButtons
                            }
                            .padding(16)
                        }
                    }
                    .navigationTitle("Definition Quiz")
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        AnalyticsService.shared.logEvent(.definitionQuizOpened)
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
                        .foregroundColor(.green)
                    
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

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Word")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(viewModel.correctWord.wordItself ?? "")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            if let partOfSpeech = viewModel.correctWord.partOfSpeech, !partOfSpeech.isEmpty {
                HStack {
                    Text(partOfSpeech)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
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
                    .foregroundColor(.blue)
                
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
                            Text(viewModel.words[index].definition ?? "")
                                .font(.body)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .clippedWithPaddingAndBackground(backgroundColor(for: index))
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
                        .foregroundColor(.red)
                    
                    Text("Incorrect! Moving to next question...")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .background(.red.opacity(0.1))
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
                Label("Skip Word (-25 points)", systemImage: "arrow.right.circle")
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
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Quiz Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Great job! You've completed the definition quiz.")
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
                                .foregroundColor(.green)
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
                        .foregroundColor(.white)
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
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
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

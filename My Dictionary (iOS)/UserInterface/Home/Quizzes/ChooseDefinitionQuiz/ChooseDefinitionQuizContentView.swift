import SwiftUI

struct ChooseDefinitionQuizContentView: View {

    @StateObject private var viewModel: ChooseDefinitionQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: ChooseDefinitionQuizViewModel(preset: preset))
    }

    var body: some View {
        ZStack {
            Color.systemGroupedBackground
                .ignoresSafeArea()

            if let errorMessage = viewModel.errorMessage {
                // Error state
                VStack(spacing: 24) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.gradient)
                        
                        Text(Loc.Quizzes.quizUnavailable.localized)
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
                    
                    ActionButton(Loc.Quizzes.backToQuizzes.localized, systemImage: "chevron.left", style: .borderedProminent) {
                        dismiss()
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
            title: Loc.Navigation.definitionQuiz.localized,
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.exit.localized) {
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
            ProgressView(
                value: Double(viewModel.questionsAnswered),
                total: Double(viewModel.preset.wordCount)
            )
            .progressViewStyle(.linear)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Loc.Quizzes.progress.localized): \(viewModel.questionsAnswered)/\(viewModel.preset.wordCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if viewModel.currentStreak > 0 {
                        Text("🔥 \(Loc.Quizzes.streak.localized): \(viewModel.currentStreak)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Loc.Quizzes.score.localized): \(viewModel.score)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.accent)

                    Text("\(Loc.Quizzes.best.localized): \(viewModel.bestStreak)")
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
                    .foregroundStyle(.accent)

                Text(Loc.Quizzes.word.localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()

                HeaderButton(icon: "speaker.wave.2.fill", size: .small) {
                    play(viewModel.correctWord.quiz_wordItself, isWord: true)
                }
            }
            
            Text(viewModel.correctWord.quiz_wordItself)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)

            TagView(
                text: PartOfSpeech(rawValue: viewModel.correctWord.quiz_partOfSpeech).displayName,
                color: .accent,
                size: .small,
                style: .regular
            )
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
                
                Text(Loc.Quizzes.chooseCorrectDefinition.localized)
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

            switch viewModel.answerFeedback {
            case .correct:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.accent)

                    Text(Loc.Quizzes.correct.localized)
                        .font(.caption)
                        .foregroundStyle(.accent)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.accent.opacity(0.2), cornerRadius: 8)
            case .incorrect:
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(Loc.Quizzes.incorrectMovingToNextQuestion.localized)
                        .font(.caption)
                        .foregroundStyle(.red)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.red.opacity(0.2), cornerRadius: 8)
            default:
                EmptyView()
            }
        }
        .padding(20)
        .clippedWithBackground(Color.secondarySystemGroupedBackground)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ActionButton(Loc.Quizzes.skipWord.localized, systemImage: "arrow.right.circle", color: .secondary) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.handle(.skipWord)
                }
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 32) {
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
                    Text(Loc.Quizzes.quizComplete.localized)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(Loc.Quizzes.greatJobCompletedDefinitionQuiz.localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Score Card
                VStack(spacing: 16) {
                    Text(Loc.Quizzes.yourResults.localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text(Loc.Quizzes.finalScore.localized)
                            Spacer()
                            Text("\(viewModel.score)")
                                .fontWeight(.bold)
                                .foregroundStyle(.accent)
                        }
                        
                        HStack {
                            Text(Loc.Quizzes.correctAnswers.localized)
                            Spacer()
                            Text("\(viewModel.correctAnswers)/\(viewModel.wordsPlayed.count)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text(Loc.Quizzes.bestStreak.localized)
                            Spacer()
                            Text("\(viewModel.bestStreak)")
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                        
                        HStack {
                            Text(Loc.Quizzes.accuracy.localized)
                            Spacer()
                            Text("\(Int((Double(viewModel.correctAnswers) / Double(viewModel.wordsPlayed.count)) * 100))%")
                                .fontWeight(.medium)
                                .foregroundStyle(.accent)
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
                ActionButton(Loc.Actions.tryAgain.localized, systemImage: "arrow.clockwise", style: .borderedProminent) {
                    viewModel.handle(.restartQuiz)
                }
                ActionButton(Loc.Quizzes.backToQuizzes.localized, systemImage: "chevron.left") {
                    dismiss()
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
            return Color.tertiarySystemGroupedBackground
        case .correct(let correctIndex):
            return index == correctIndex ? Color.accent.opacity(0.2) : Color.tertiarySystemGroupedBackground
        case .incorrect(let incorrectIndex):
            return index == incorrectIndex ? Color.red.opacity(0.2) : Color.tertiarySystemGroupedBackground
        }
    }

    private func borderColor(for index: Int) -> Color {
        switch viewModel.answerFeedback {
        case .none:
            return Color.clear
        case .correct(let correctIndex):
            return index == correctIndex ? Color.accent : Color.clear
        case .incorrect(let incorrectIndex):
            return index == incorrectIndex ? Color.red : Color.clear
        }
    }

    private func play(_ text: String?, isWord: Bool = false) {
        Task { @MainActor in
            guard let text else { return }

            do {
                try await TTSPlayer.shared.play(
                    text,
                    targetLanguage: isWord
                    ? viewModel.correctWord.quiz_languageCode
                    : Locale.current.language.languageCode?.identifier
                )
            } catch {
                errorReceived(error)
            }
        }
    }
}

import SwiftUI

struct ChooseDefinitionQuizView: View {

    @StateObject private var viewModel: ChooseDefinitionQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: ChooseDefinitionQuizViewModel(
            preset: preset
        ))
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
                        VStack(spacing: 12) {
                            progressBar
                            wordCard
                            optionsSection
                            actionButtons
                        }
                        .padding(12)
                    }
                } else {
                    QuizResultsView(
                        model: .init(
                            quiz: .chooseDefinition,
                            score: viewModel.score,
                            correctAnswers: viewModel.correctAnswers,
                            wordsPlayed: viewModel.wordsPlayed.count,
                            accuracyContributions: .zero, // for spelling quiz
                            bestStreak: viewModel.bestStreak
                        ),
                        onRestart: {
                            viewModel.handle(.restartQuiz)
                        }
                    )
                }
            }
        }
        .navigationTitle(Loc.Navigation.definitionQuiz.localized)
        .onAppear {
            AnalyticsService.shared.logEvent(.definitionQuizOpened)
        }
        .onDisappear {
            // Handle early exit - save current progress if quiz is in progress
            if !viewModel.isQuizComplete {
                viewModel.handle(.saveSession)
            }
        }
        .onReceive(viewModel.dismissPublisher) {
            dismiss()
        }
    }

    private var progressBar: some View {
        QuizProgressHeader(
            model: .init(
                wordsPlayed: viewModel.wordsPlayed.count,
                totalQuestions: viewModel.preset.wordCount,
                currentStreak: viewModel.currentStreak,
                score: viewModel.score,
                bestStreak: viewModel.bestStreak
            )
        )
        .clippedWithPaddingAndBackground(cornerRadius: 16, showShadow: true)
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
            
            if case .incorrect = viewModel.answerFeedback {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    
                    Text(Loc.Quizzes.incorrectMovingToNextQuestion.localized)
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

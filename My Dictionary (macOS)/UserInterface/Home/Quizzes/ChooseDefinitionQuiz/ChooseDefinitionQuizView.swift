import SwiftUI

struct ChooseDefinitionQuizView: View {

    @StateObject private var viewModel: ChooseDefinitionQuizViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared

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
                        
                        Text(Loc.Quizzes.quizUnavailable)
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
                    
                    ActionButton(Loc.Quizzes.backToQuizzes, systemImage: "chevron.left", style: .borderedProminent) {
                        dismiss()
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            } else if viewModel.items.isNotEmpty {
                if !viewModel.isQuizComplete {
                    ScrollView {
                        VStack(spacing: 12) {
                            progressBar
                            itemCard
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
                            itemsPlayed: viewModel.itemsPlayed.count,
                            accuracyContributions: .zero, // for spelling quiz
                            bestStreak: viewModel.bestStreak
                        )
                    )
                }
            }
        }
        .navigationTitle(Loc.Navigation.definitionQuiz)
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
                itemsPlayed: viewModel.itemsPlayed.count,
                totalQuestions: viewModel.preset.itemCount,
                currentStreak: viewModel.currentStreak,
                score: viewModel.score,
                bestStreak: viewModel.bestStreak
            )
        )
        .clippedWithPaddingAndBackground(in: .rect(cornerRadius: 16), showShadow: true)
    }

    private var itemCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundStyle(.accent)

                switch viewModel.correctItem.quiz_itemType {
                case .word, .sharedWord:
                    Text(Loc.Words.word)
                        .font(.headline)
                        .fontWeight(.semibold)
                case .idiom:
                    Text(Loc.Words.idiom)
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                AsyncHeaderButton(
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(viewModel.correctItem.quiz_text, isItem: true)
                }
                .disabled(ttsPlayer.isPlaying)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(viewModel.correctItem.quiz_text)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    TagView(
                        text: PartOfSpeech(rawValue: viewModel.correctItem.quiz_partOfSpeech).displayName,
                        color: .accent,
                        size: .small,
                        style: .regular
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Word Image (if available)
                if let imageLocalPath = viewModel.correctItem.quiz_imageLocalPath {
                    QuizImageView(localPath: imageLocalPath, webUrl: viewModel.correctItem.quiz_imageUrl)
                }
            }
        }
        .padding(20)
        .clippedWithBackground()
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.circle")
                    .font(.title2)
                    .foregroundStyle(.accent)
                
                Text(Loc.Quizzes.chooseCorrectDefinition)
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
                            Text(viewModel.items[index].quiz_definition)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .clippedWithPaddingAndBackground(backgroundColor(for: index), in: .rect(cornerRadius: 12))
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

                    Text(Loc.Quizzes.correct)
                        .font(.caption)
                        .foregroundStyle(.accent)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.accent.opacity(0.2), in: .rect(cornerRadius: 8))
            case .incorrect:
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(Loc.Quizzes.incorrectMovingToNextQuestion)
                        .font(.caption)
                        .foregroundStyle(.red)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.red.opacity(0.2), in: .rect(cornerRadius: 8))
            default:
                EmptyView()
            }
        }
        .padding(20)
        .clippedWithBackground(Color.secondarySystemGroupedBackground)
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            ActionButton(
                Loc.Quizzes.skipWord,
                systemImage: "arrow.right.circle",
                color: .secondary
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.handle(.skipItem)
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

    private func play(_ text: String?, isItem: Bool = false) async throws {
        guard let text else { return }
        try await ttsPlayer.play(text)
    }
}

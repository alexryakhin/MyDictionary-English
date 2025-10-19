import SwiftUI

struct ChooseDefinitionQuizContentView: View {

    @StateObject private var viewModel: ChooseDefinitionQuizViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared

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
                        VStack(spacing: 16) {
                            // Word Card
                            wordCard

                            // Options Section
                            optionsSection

                            // Action Buttons
                            actionButtons
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .if(isPad) { view in
                            view
                                .frame(maxWidth: 550, alignment: .center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                } else {
                    QuizResultsView(
                        model: .init(
                            quiz: .chooseDefinition,
                            score: viewModel.score,
                            correctAnswers: viewModel.correctAnswers,
                            itemsPlayed: viewModel.itemsPlayed.count,
                            accuracyContributions: 0,
                            bestStreak: viewModel.bestStreak
                        ),
                        onFinish: {
                            dismiss()
                        }
                    )
                }
            }
        }
        .navigation(
            title: Loc.Navigation.definitionQuiz,
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.exit) {
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
            if !viewModel.isQuizComplete && viewModel.itemsPlayed.count > 0 {
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
                total: Double(viewModel.preset.itemCount)
            )
            .progressViewStyle(.linear)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Loc.Quizzes.progress): \(viewModel.questionsAnswered)/\(viewModel.preset.itemCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if viewModel.currentStreak > 0 {
                        Text("🔥 \(Loc.Quizzes.streak): \(viewModel.currentStreak)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Loc.Quizzes.score): \(viewModel.score)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.accent)

                    Text("\(Loc.Quizzes.best): \(viewModel.bestStreak)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundStyle(.accent)

                Text(Loc.Quizzes.word)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()

                AsyncHeaderButton(icon: "speaker.wave.2.fill", size: .small) {
                    try await play(viewModel.correctItem.quiz_text, isWord: true)
                }
                .disabled(ttsPlayer.isPlaying)
            }

            // Word Image (if available)
            if let imageLocalPath = viewModel.correctItem.quiz_imageLocalPath {
                HStack(alignment: .bottom, spacing: 8) {
                    QuizImageView(localPath: imageLocalPath, webUrl: viewModel.correctItem.quiz_imageUrl)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.correctItem.quiz_text)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)

                TagView(
                    text: PartOfSpeech(rawValue: viewModel.correctItem.quiz_partOfSpeech).displayName,
                    color: .accent,
                    size: .small,
                    style: .regular
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
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
            if !viewModel.isLastQuestion {
                ActionButton(Loc.Quizzes.skipWord, systemImage: "arrow.right.circle", color: .secondary) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.handle(.skipItem)
                    }
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

    private func play(
        _ text: String?,
        isWord: Bool = false
    ) async throws {
        guard let text else { return }
        try await ttsPlayer.play(
            text,
            languageCode: isWord ? viewModel.correctItem.quiz_languageCode : nil
        )
    }
}

import SwiftUI

struct FillInTheBlankQuizContentView: View {

    @StateObject private var viewModel: FillInTheBlankQuizViewModel
    @StateObject private var ttsPlayer = TTSPlayer.shared

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: FillInTheBlankQuizViewModel(preset: preset))
    }

    var body: some View {
        if case .error(let errorMessage) = viewModel.loadingStatus {
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

                if errorMessage == Loc.Ai.AiError.proRequired {
                    ActionButton(
                        Loc.Subscription.Paywall.upgradeToPro,
                        style: .borderedProminent
                    ) {
                        PaywallService.shared.presentPaywall(for: .aiQuizzes)
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .groupedBackground()
        } else if viewModel.items.isNotEmpty && !viewModel.isQuizComplete && viewModel.aiStory != nil && viewModel.loadingStatus == .ready {
            ScrollView {
                VStack(spacing: 16) {
                    headerView

                    // Story Section
                    if let story = viewModel.aiStory {
                        storySection(story)
                    }

                    // Options Section
                    if let story = viewModel.aiStory {
                        optionsSection(story)
                    }

                    // AI Explanation Section
                    if viewModel.isAnswerSubmitted, let story = viewModel.aiStory {
                        aiExplanationSection(story)
                    }

                    // Action Buttons
                    actionButtons
                }
                .padding(12)
            }
            .groupedBackground()
            .onAppear {
                AnalyticsService.shared.logEvent(.fillInTheBlankQuizOpened)
            }
            .onDisappear {
                // Handle early exit - save current progress if quiz is in progress
                if !viewModel.isQuizComplete && viewModel.itemsPlayed.count > 0 {
                    viewModel.handle(.dismiss)
                }
            }
        } else if viewModel.isQuizComplete {
            QuizResultsView(
                model: .init(
                    quiz: .fillInTheBlank,
                    score: viewModel.score,
                    correctAnswers: viewModel.correctAnswers,
                    itemsPlayed: viewModel.itemsPlayed.count,
                    accuracyContributions: viewModel.accuracyContributions.values.reduce(0, +),
                    bestStreak: viewModel.bestStreak
                ),
                showStreak: viewModel.showStreakAnimation,
                currentDayStreak: viewModel.currentDayStreak
            )
        } else {
            // Loading state - show AI loading animation
            VStack(spacing: 24) {
                Spacer()

                switch viewModel.loadingStatus {
                case .initializing, .generatingFirstStory:
                    VStack(spacing: 24) {
                        AICircularProgressAnimation()
                            .frame(maxWidth: 300)

                        Text(Loc.Quizzes.Loading.generatingFillInBlankStories)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(Loc.Quizzes.Loading.fillInBlankDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)

                case .prefetching:
                    // Show loading only when waiting for the current item to be available
                    VStack(spacing: 24) {
                        AICircularProgressAnimation()
                            .frame(maxWidth: 300)

                        Text(Loc.Quizzes.Loading.loadingNextStory)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(Loc.Quizzes.Loading.preparingNextStory)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 32)

                case .error(let errorMessage):
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.purple.gradient)

                            Text(Loc.Quizzes.Loading.failedToLoadQuiz)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(errorMessage)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)

                        ActionButton(
                            Loc.Actions.retry,
                            systemImage: "arrow.clockwise",
                            style: .borderedProminent
                        ) {
                            viewModel.handle(.retry)
                        }
                        .padding(.horizontal, 32)
                    }

                case .ready:
                    // This should not happen in this else block, but just in case
                    EmptyView()
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .groupedBackground()
        }
    }

    private var headerView: some View {
        QuizProgressHeader(
            model: .init(
                itemsPlayed: viewModel.itemsPlayed.count,
                totalQuestions: viewModel.totalQuestions,
                currentStreak: viewModel.currentStreak,
                score: viewModel.score,
                bestStreak: viewModel.bestStreak
            )
        )
        .clippedWithPaddingAndBackground(in: .rect(cornerRadius: 16), showShadow: true)
    }

    private func storySection(_ story: AIFillInTheBlankStory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book")
                    .font(.title2)
                    .foregroundStyle(.accent)

                Text(Loc.Quizzes.AiQuiz.storyContext)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(story.story)
                }
                .disabled(ttsPlayer.isPlaying || story.story.isEmpty)
            }

            InteractiveText(
                text: story.story,
                font: .headline
            )
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func optionsSection(_ story: AIFillInTheBlankStory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.circle")
                    .font(.title2)
                    .foregroundStyle(.accent)

                Text(Loc.Quizzes.Ui.options)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(Array(viewModel.shuffledOptions.enumerated()), id: \.offset) { index, option in
                    Button {
                        if !viewModel.isAnswerSubmitted {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.handle(.selectOption(index))
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("\(index + 1).")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)

                            Text(option.text)
                                .font(.body)
                                .lineSpacing(2)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(optionColor(for: index))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.accent)
                                .opacity(viewModel.selectedOptionIndex == index ? 1 : 0)
                        }
                        .padding(16)
                        .background(optionBackgroundColor(for: index))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isAnswerSubmitted)
                }
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func aiExplanationSection(_ story: AIFillInTheBlankStory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: viewModel.isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.isAnswerCorrect ? .green : .red)

                Text(Loc.Quizzes.AiQuiz.explanation)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Show the explanation for the selected option or general explanation for skipped questions
            if let selectedIndex = viewModel.selectedOptionIndex,
               selectedIndex < viewModel.shuffledOptions.count {
                let selectedOption = viewModel.shuffledOptions[selectedIndex]
                Text(selectedOption.explanation)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            } else {
                // Show general explanation for skipped questions
                Text(Loc.Quizzes.Ui.youSkippedQuestion)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                Text(story.explanation)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isMovingOnToNextWord = viewModel.isAnswerSubmitted
        VStack(spacing: 12) {
            ActionButton(
                isMovingOnToNextWord ? (viewModel.isLastQuestion ? Loc.Quizzes.finish : Loc.Quizzes.nextWord) : Loc.Quizzes.submitAnswer,
                systemImage: isMovingOnToNextWord ? (viewModel.isLastQuestion ? "checkmark.circle.fill" : "arrow.right.circle.fill") : "checkmark.circle.fill",
                style: .borderedProminent
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isMovingOnToNextWord {
                        viewModel.handle(.nextItem)
                    } else {
                        viewModel.handle(.submitAnswer)
                    }
                }
            }
            .disabled((viewModel.selectedOptionIndex == nil && !viewModel.isAnswerSubmitted) || viewModel.loadingStatus != .ready)

            if !viewModel.isLastQuestion {
                ActionButton(Loc.Quizzes.skipWord, systemImage: "arrow.right.circle") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.handle(.skipItem)
                    }
                }
                .disabled(isMovingOnToNextWord || viewModel.loadingStatus != .ready)
            }
        }
    }



    // MARK: - Helper Functions

    private func optionColor(for index: Int) -> Color {
        if !viewModel.isAnswerSubmitted {
            return viewModel.selectedOptionIndex == index ? .accent : .primary
        } else {
            if index == viewModel.correctAnswerIndex {
                return .green
            } else if index == viewModel.selectedOptionIndex {
                return .red
            } else {
                return .secondary
            }
        }
    }

    private func optionBackgroundColor(for index: Int) -> Color {
        if !viewModel.isAnswerSubmitted {
            return viewModel.selectedOptionIndex == index ? .accent.opacity(0.2) : .tertiarySystemGroupedBackground
        } else {
            if index == viewModel.correctAnswerIndex {
                return .green.opacity(0.2)
            } else if index == viewModel.selectedOptionIndex {
                return .red.opacity(0.2)
            } else {
                return .tertiarySystemGroupedBackground
            }
        }
    }

    private func play(_ text: String) async throws {
        guard !text.isEmpty else { return }
        try await ttsPlayer.play(text)
    }
}

// MARK: - Stat Row Helper

private struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    FillInTheBlankQuizContentView(preset: QuizPreset(itemCount: 10, hardItemsOnly: false, mode: .all))
}

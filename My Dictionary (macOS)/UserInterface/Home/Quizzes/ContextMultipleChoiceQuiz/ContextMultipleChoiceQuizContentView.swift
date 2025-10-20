import SwiftUI

struct ContextMultipleChoiceQuizContentView: View {

    @StateObject private var viewModel: ContextMultipleChoiceQuizViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: ContextMultipleChoiceQuizViewModel(preset: preset))
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
                
                ActionButton(
                    Loc.Quizzes.backToQuizzes,
                    systemImage: "chevron.left",
                    style: .borderedProminent
                ) {
                    dismiss()
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .groupedBackground()
            .onReceive(viewModel.dismissPublisher) {
                dismiss()
            }
        } else if let contextQuestion = viewModel.aiContextQuestion, viewModel.items.isNotEmpty && !viewModel.isQuizComplete && viewModel.loadingStatus == .ready {
            // Quiz content is ready
            ScrollView {
                VStack(spacing: 16) {
                    headerView
                    
                    // Question Section
                    questionSection(contextQuestion)

                    // Options Section
                    optionsSection(contextQuestion)

                    // AI Explanation Section
                    if viewModel.isAnswerSubmitted {
                        aiExplanationSection(contextQuestion)
                    }

                    // Action Buttons
                    actionButtons
                }
                .padding(12)
            }
            .groupedBackground()
            .onAppear {
                AnalyticsService.shared.logEvent(.contextMultipleChoiceQuizOpened)
            }
            .onDisappear {
                // Handle early exit - save current progress if quiz is in progress
                if !viewModel.isQuizComplete && viewModel.itemsPlayed.count > 0 {
                    viewModel.handle(.dismiss)
                }
            }
            .onReceive(viewModel.dismissPublisher) {
                dismiss()
            }
        } else if viewModel.isQuizComplete {
            QuizResultsView(
                model: .init(
                    quiz: .contextMultipleChoice,
                    score: viewModel.score,
                    correctAnswers: viewModel.correctAnswers,
                    itemsPlayed: viewModel.itemsPlayed.count,
                    accuracyContributions: viewModel.accuracyContributions.values.reduce(0, +),
                    bestStreak: viewModel.bestStreak
                )
            )
        } else {
            // Loading state - show AI loading animation
            VStack(spacing: 24) {
                Spacer()
                
                switch viewModel.loadingStatus {
                case .initializing, .generatingFirstQuestion:
                    VStack(spacing: 24) {
                        AICircularProgressAnimation()
                            .frame(maxWidth: 300)
                        
                        Text(Loc.Quizzes.Loading.generatingContextQuestions)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(Loc.Quizzes.Loading.contextQuestionsDescription)
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
                        
                        Text(Loc.Quizzes.Loading.loadingNextQuestion)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(Loc.Quizzes.Loading.preparingNextQuestion)
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
                                .foregroundStyle(.orange.gradient)
                            
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

    private func questionSection(_ contextQuestion: AIContextQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let question = Loc.Quizzes.AiQuiz.chooseCorrectSentence(contextQuestion.word)
            HStack {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundStyle(.accent)
                
                Text(Loc.Quizzes.Ui.question)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                AsyncHeaderButton(
                    Loc.Actions.listen,
                    icon: "speaker.wave.2.fill",
                    size: .small
                ) {
                    try await play(question)
                }
                .disabled(ttsPlayer.isPlaying || question.isEmpty)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(question)
                        .font(.body)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    HStack {
                        TagView(
                            text: PartOfSpeech(rawValue: viewModel.currentItem?.quiz_partOfSpeech).displayName,
                            color: .accent,
                            size: .small,
                            style: .regular
                        )
                        if let languageCode = viewModel.currentItem?.quiz_languageCode {
                            TagView(
                                text: languageCode.uppercased(),
                                color: .blue,
                                size: .small,
                                style: .regular
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Word Image (if available)
                if let imageLocalPath = viewModel.currentItem?.quiz_imageLocalPath {
                    QuizImageView(localPath: imageLocalPath, webUrl: viewModel.currentItem?.quiz_imageUrl)
                }
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func optionsSection(_ contextQuestion: AIContextQuestion) -> some View {
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

    private func aiExplanationSection(_ contextQuestion: AIContextQuestion) -> some View {
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
            
            // Show the explanation for the selected option
            if let selectedIndex = viewModel.selectedOptionIndex,
               selectedIndex < viewModel.shuffledOptions.count {
                let selectedOption = viewModel.shuffledOptions[selectedIndex]
                Text(selectedOption.explanation)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            } else {
                Text(contextQuestion.explanation)
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
    ContextMultipleChoiceQuizContentView(preset: QuizPreset(itemCount: 10, hardItemsOnly: false, mode: .all))
}

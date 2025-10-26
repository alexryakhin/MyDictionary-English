import SwiftUI

struct SentenceWritingQuizContentView: View {

    @StateObject private var viewModel: SentenceWritingQuizViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @State private var showingDetailedExplanations = false

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: SentenceWritingQuizViewModel(preset: preset))
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
        } else if !viewModel.isQuizComplete {
            ScrollView {
                VStack(spacing: 16) {
                    // Word Card
                    wordCard

                    // Sentence Input Section
                    sentenceInputSection

                    // AI Evaluation Section
                    if viewModel.isShowingAIEvaluation, let evaluation = viewModel.aiEvaluation {
                        aiEvaluationSection(evaluation)
                    }

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
            .groupedBackground()
            .navigation(
                title: Loc.Navigation.sentenceWritingQuiz,
                mode: .inline,
                trailingContent: {
                    HeaderButton(Loc.Actions.exit) {
                        dismiss()
                    }
                },
                bottomContent: {
                    headerView
                }
            )
            .onAppear {
                AnalyticsService.shared.logEvent(.sentenceWritingQuizOpened)
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
        } else {
            QuizResultsView(
                model: .init(
                    quiz: .sentenceWriting,
                    score: viewModel.score,
                    correctAnswers: viewModel.correctAnswers,
                    itemsPlayed: viewModel.itemsPlayed.count,
                    accuracyContributions: viewModel.accuracyContributions.values.reduce(0, +),
                    bestStreak: viewModel.bestStreak
                ),
                showStreak: viewModel.showStreakAnimation,
                currentDayStreak: viewModel.currentDayStreak,
                additionalAction: {
                    if !viewModel.itemsPlayed.isEmpty {
                        ActionButton(
                            Loc.Quizzes.AiQuiz.viewDetailedExplanations,
                            systemImage: "text.magnifyingglass",
                            style: .bordered
                        ) {
                            showingDetailedExplanations = true
                        }
                    }
                },
                onFinish: {
                    dismiss()
                }
            )
            .sheet(isPresented: $showingDetailedExplanations) {
                DetailedExplanationsView(
                    evaluations: viewModel.allEvaluations,
                    itemsPlayed: viewModel.itemsPlayed,
                    evaluationMapping: viewModel.evaluationMapping
                )
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            // Progress Bar
            ProgressView(value: Double(viewModel.itemsPlayed.count), total: Double(viewModel.totalQuestions))
                .progressViewStyle(.linear)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Loc.Quizzes.progress): \(viewModel.itemsPlayed.count)/\(viewModel.totalQuestions)")
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
                        .foregroundStyle(.blue)

                    Text("\(Loc.Quizzes.best): \(viewModel.bestStreak)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            let question = Loc.Quizzes.AiQuiz.writeSentenceForWord(viewModel.currentItem?.quiz_text.trimmed.lowercased() ?? "")
            HStack {
                Image(systemName: "text.bubble")
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

            // Word Image (if available)
            if let imageLocalPath = viewModel.currentItem?.quiz_imageLocalPath {
                HStack {
                    QuizImageView(localPath: imageLocalPath, webUrl: viewModel.currentItem?.quiz_imageUrl)
                    Spacer()
                }
            }

            Text(question)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

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
                Spacer()
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var sentenceInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.title2)
                    .foregroundStyle(.accent)

                Text(Loc.Quizzes.AiQuiz.sentencePlaceholder)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            TextField(Loc.Quizzes.AiQuiz.sentencePlaceholder, text: $viewModel.sentenceTextField, axis: .vertical)
                .padding(vertical: 8, horizontal: 12)
                .background(Color.tertiarySystemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(viewModel.isLoading || viewModel.isShowingAIEvaluation)
                .onSubmit {
                    if !viewModel.isLoading && !viewModel.isShowingAIEvaluation && !viewModel.sentenceTextField.trimmed.isEmpty {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.handle(.submitSentence)
                        }
                    }
                }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func aiEvaluationSection(_ evaluation: AISentenceEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: evaluation.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(evaluation.isCorrect ? .green : .red)

                Text(Loc.Quizzes.AiQuiz.feedback)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Scores
            VStack(spacing: 8) {
                HStack {
                    Text(Loc.Quizzes.AiQuiz.usageScore(evaluation.usageScore))
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Spacer()
                    Text(Loc.Quizzes.AiQuiz.grammarScore(evaluation.grammarScore))
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                    Text(Loc.Quizzes.AiQuiz.overallScore(evaluation.overallScore))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(evaluation.isCorrect ? .green : .red)
                }

                // Progress bars
                VStack(spacing: 4) {
                    ProgressView(value: Double(evaluation.usageScore), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)

                    ProgressView(value: Double(evaluation.grammarScore), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .frame(height: 4)

                    ProgressView(value: Double(evaluation.overallScore), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: evaluation.isCorrect ? .green : .red))
                        .frame(height: 6)
                }
            }

            // Feedback
            Text(evaluation.feedback)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)

            // Suggestions
            if !evaluation.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.Quizzes.Ui.suggestions)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(evaluation.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundStyle(.blue)
                            Text(suggestion)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isMovingOnToNextWord = viewModel.isShowingAIEvaluation
        VStack(spacing: 12) {
            ActionButton(
                isMovingOnToNextWord ? Loc.Quizzes.nextWord : Loc.Quizzes.AiQuiz.submitForEvaluation,
                systemImage: isMovingOnToNextWord ? "arrow.right.circle.fill" : "paperplane.fill",
                style: .borderedProminent
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isMovingOnToNextWord {
                        viewModel.handle(.nextItem)
                    } else {
                        viewModel.handle(.submitSentence)
                    }
                }
            }
            .disabled(viewModel.sentenceTextField.trimmed.isEmpty || viewModel.isLoading)

            if !viewModel.isLastQuestion {
                ActionButton(Loc.Quizzes.skipWord, systemImage: "arrow.right.circle") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.handle(.skipItem)
                    }
                }
                .disabled(isMovingOnToNextWord || viewModel.isLoading)
            }
        }
    }

    private func play(_ text: String) async throws {
        guard !text.isEmpty else { return }
        try await ttsPlayer.play(text)
    }
}

// MARK: - Detailed Explanations View

struct DetailedExplanationsView: View {
    let evaluations: [AISentenceEvaluation]
    let itemsPlayed: [any Quizable]
    let evaluationMapping: [String: AISentenceEvaluation]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(itemsPlayed.enumerated()), id: \.offset) { index, item in
                        if let evaluation = evaluationMapping[item.quiz_text.trimmed.lowercased()] {
                            DetailedExplanationCard(
                                evaluation: evaluation,
                                word: item.quiz_text,
                                questionNumber: index + 1
                            )
                        } else {
                            // For skipped items, show a placeholder card
                            SkippedItemCard(
                                word: item.quiz_text,
                                questionNumber: index + 1
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .groupedBackground()
            .navigation(
                title: Loc.Quizzes.AiQuiz.detailedExplanations,
                mode: .inline,
                trailingContent: {
                    HeaderButton(Loc.Actions.done) {
                        dismiss()
                    }
                }
            )
        }
    }
}

// MARK: - Detailed Explanation Card

struct DetailedExplanationCard: View {
    let evaluation: AISentenceEvaluation
    let word: String
    let questionNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(Loc.Quizzes.Ui.questionNumber(questionNumber))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: evaluation.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(evaluation.isCorrect ? .green : .red)
            }

            // Word
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.Quizzes.word)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(word)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.accent)
            }

            // Sentence
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.Quizzes.AiQuiz.yourSentence)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(evaluation.sentence)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Scores
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.Quizzes.AiQuiz.usageScore(evaluation.usageScore))
                            .font(.caption)
                            .foregroundStyle(.blue)
                        ProgressView(value: Double(evaluation.usageScore), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(Loc.Quizzes.AiQuiz.grammarScore(evaluation.grammarScore))
                            .font(.caption)
                            .foregroundStyle(.orange)
                        ProgressView(value: Double(evaluation.grammarScore), total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .frame(height: 4)
                    }
                }

                HStack {
                    Text(Loc.Quizzes.AiQuiz.overallScore(evaluation.overallScore))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(evaluation.isCorrect ? .green : .red)
                    Spacer()
                }

                ProgressView(value: Double(evaluation.overallScore), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: evaluation.isCorrect ? .green : .red))
                    .frame(height: 6)
            }

            // Feedback
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.Quizzes.AiQuiz.feedback)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(evaluation.feedback)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }

            // Suggestions
            if !evaluation.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.Quizzes.AiQuiz.suggestions)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(evaluation.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text(suggestion)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Skipped Item Card

struct SkippedItemCard: View {
    let word: String
    let questionNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(Loc.Quizzes.Ui.questionNumber(questionNumber))
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "arrow.right.circle")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            // Word
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.Quizzes.word)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(word)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.accent)
            }

            // Skipped message
            VStack(alignment: .leading, spacing: 8) {
                Text(Loc.Quizzes.AiQuiz.skippedWord)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(Loc.Quizzes.AiQuiz.skippedWordMessage)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .label.opacity(0.05), radius: 8, x: 0, y: 2)
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
    SentenceWritingQuizContentView(preset: QuizPreset(itemCount: 10, hardItemsOnly: false, mode: .all))
}

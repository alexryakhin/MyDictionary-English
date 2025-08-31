import SwiftUI

struct SpellingQuizContentView: View {

    @StateObject private var viewModel: SpellingQuizViewModel
    @Environment(\.dismiss) private var dismiss

    init(preset: QuizPreset) {
        self._viewModel = StateObject(wrappedValue: SpellingQuizViewModel(preset: preset))
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
            .groupedBackground()
            .onReceive(viewModel.dismissPublisher) {
                dismiss()
            }
        } else if !viewModel.isQuizComplete {
            ScrollView {
                VStack(spacing: 16) {
                    // Definition Card
                    definitionCard

                    // Answer Section
                    answerSection

                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 16)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .groupedBackground()
            .navigation(
                title: Loc.Navigation.spellingQuiz,
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
                AnalyticsService.shared.logEvent(.spellingQuizOpened)
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
                    quiz: .spelling,
                    score: viewModel.score,
                    correctAnswers: viewModel.correctAnswers,
                    itemsPlayed: viewModel.itemsPlayed.count,
                    accuracyContributions: viewModel.accuracyContributions.values.reduce(0, +),
                    bestStreak: viewModel.bestStreak
                ),
                onFinish: {
                    dismiss()
                }
            )
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

    private var definitionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.quote")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(Loc.Words.definition)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            Text(viewModel.randomItem?.quiz_definition ?? "")
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)

            HStack {
                TagView(
                    text: PartOfSpeech(rawValue: viewModel.randomItem?.quiz_partOfSpeech).displayName,
                    color: .accent,
                    size: .small,
                    style: .regular
                )
                if let languageCode = viewModel.randomItem?.quiz_languageCode {
                    TagView(
                        text: languageCode.uppercased(),
                        color: .blue,
                        size: .small,
                        style: .regular
                    )
                }
                Spacer()
            }

            // Hint section
            if viewModel.isShowingHint, let randomItem = viewModel.randomItem {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)

                    Text("\(Loc.Quizzes.hint): \(Loc.Quizzes.wordStartsWith) '\(randomItem.quiz_text.prefix(1).uppercased())'")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.title2)
                    .foregroundStyle(.accent)

                Text(Loc.Quizzes.yourAnswer)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if viewModel.attemptCount > 0 {
                    Text("\(Loc.Quizzes.attempt) \(viewModel.attemptCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            TextField(Loc.Words.typeWordHere, text: $viewModel.answerTextField, axis: .vertical)
                .padding(vertical: 8, horizontal: 12)
                .background(Color.tertiarySystemGroupedBackground)
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
                        .foregroundStyle(.accent)

                    Text([Loc.Quizzes.correct, Loc.Quizzes.wellDone, Loc.Quizzes.keepUpGoodWork].randomElement() ?? Loc.Quizzes.correct)
                        .font(.caption)
                        .foregroundStyle(.accent)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.accent.opacity(0.2), cornerRadius: 8)
            } else if viewModel.attemptCount >= 3 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)

                    Text(Loc.Quizzes.correctWordIs(viewModel.randomItem?.quiz_text ?? ""))
                        .font(.caption)
                        .foregroundStyle(.red)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.red.opacity(0.2), cornerRadius: 8)
            } else if !viewModel.isCorrectAnswer && viewModel.attemptCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(incorrectMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Spacer()
                }
                .padding(vertical: 8, horizontal: 12)
                .clippedWithBackground(.orange.opacity(0.2), cornerRadius: 8)
            }
        }
        .padding(20)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var actionButtons: some View {
        let isMovingOnToNextWord = viewModel.isShowingCorrectAnswer || viewModel.attemptCount >= 3
        VStack(spacing: 12) {
            ActionButton(
                isMovingOnToNextWord ? Loc.Quizzes.nextWord : Loc.Quizzes.submitAnswer,
                systemImage: isMovingOnToNextWord ? "arrow.right.circle.fill" : "checkmark.circle.fill",
                style: .borderedProminent
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isMovingOnToNextWord {
                        viewModel.handle(.nextItem)
                    } else {
                        viewModel.handle(.confirmAnswer)
                    }
                }
            }
            .disabled(viewModel.answerTextField.isEmpty)

            if !viewModel.isLastQuestion {
                ActionButton(Loc.Quizzes.skipWord, systemImage: "arrow.right.circle") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.handle(.skipItem)
                    }
                }
                .disabled(isMovingOnToNextWord)
            }
        }
    }

    private var incorrectMessage: String {
        guard let randomItem = viewModel.randomItem else { return "" }

        if viewModel.attemptCount > 2 {
            return Loc.Quizzes.QuizActions.yourWordIs(randomItem.quiz_text.trimmed)
        } else {
            return Loc.Quizzes.QuizActions.incorrectTryAgain
        }
    }
}

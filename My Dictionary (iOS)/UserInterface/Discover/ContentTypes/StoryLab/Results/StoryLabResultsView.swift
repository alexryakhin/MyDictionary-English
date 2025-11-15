//
//  StoryLabResultsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI
import Flow

struct StoryLabResultsView: View {
    private let config: StoryLabResultsConfig
    @StateObject private var viewModel: StoryLabResultsViewModel
    @State private var showConfetti = false
    @State private var selectedPageIndex: Int?
    @State private var hasLoggedAppear = false

    init(config: StoryLabResultsConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: StoryLabResultsViewModel(config: config))
    }

    var body: some View {
        Group {
            if let session = viewModel.session, let story = viewModel.story {
                resultsContent(session: session, story: story)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .groupedBackgroundWithConfetti(isActive: $showConfetti)
        .navigation(
            title: Loc.StoryLab.Results.title,
            mode: .regular,
            trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    NavigationManager.shared.popToRoot()
                }
            }
        )
        .overlay {
            if viewModel.showStreakAnimation, let streak = viewModel.currentDayStreak {
                StreakProgressionAnimation(
                    isActive: Binding(
                        get: { viewModel.showStreakAnimation },
                        set: { isActive in
                            viewModel.handle(.setStreakAnimationActive(isActive))
                        }
                    ),
                    targetStreak: streak
                )
            }
        }
        .onAppear {
            viewModel.handle(.refresh)
            updateCelebrationState()
        }
        .onChange(of: viewModel.score) { _ in
            updateCelebrationState()
        }
        .sheet(item: Binding(
            get: { selectedPageIndex.map { $0 } },
            set: { selectedPageIndex = $0 }
        )) { pageIndex in
            if let session = viewModel.session,
               let story = viewModel.story,
               pageIndex < story.pages.count {
                StoryLabPageDetailView(
                    page: story.pages[pageIndex],
                    pageIndex: pageIndex,
                    session: session,
                    story: story
                )
            }
        }
        .onAppear {
            guard !hasLoggedAppear else { return }
            hasLoggedAppear = true
            if let session = viewModel.session, let story = viewModel.story {
                AnalyticsService.shared.logEvent(
                    .storyLabResultsOpened,
                    parameters: [
                        "session_id": session.id.uuidString,
                        "score": session.score,
                        "correct_answers": session.correctAnswers,
                        "total_questions": session.totalQuestions,
                        "pages_total": story.pages.count
                    ]
                )
            }
        }
    }

    private func resultsContent(session: StorySession, story: AIStoryResponse) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                scoreSummarySection(score: viewModel.score, correct: viewModel.correctAnswers, total: viewModel.totalQuestions)
                performanceBreakdownSection(session: session, story: story)
                if viewModel.discoveredWords.isNotEmpty {
                    discoveredWordsSection(words: viewModel.discoveredWords)
                }
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func scoreSummarySection(score: Int, correct: Int, total: Int) -> some View {
        CustomSectionView(header: Loc.StoryLab.Results.summary) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(
                            score >= 70 ? Color.green :
                            score >= 50 ? Color.orange :
                            Color.red,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: score)

                    VStack(spacing: 4) {
                        Text("\(score)%")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(Loc.StoryLab.Results.score)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text(correct.formatted())
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(Loc.StoryLab.Results.correctAnswers)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        Text(total.formatted())
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(Loc.StoryLab.Results.totalQuestions)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func performanceBreakdownSection(session: StorySession, story: AIStoryResponse) -> some View {
        CustomSectionView(header: Loc.Quizzes.yourResults) {
            VStack(spacing: 12) {
                ForEach(Array(story.pages.enumerated()), id: \.offset) { index, page in
                    pagePerformanceRow(pageIndex: index, page: page, session: session, totalPages: story.pages.count)
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func pagePerformanceRow(pageIndex: Int, page: AIStoryPage, session: StorySession, totalPages: Int) -> some View {
        let pageAnswers = page.questions.enumerated().map { questionIndex, _ -> Bool? in
            let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: questionIndex)
            guard let userAnswer = session.answers[key],
                  userAnswer < page.questions[questionIndex].options.count else { return nil }
            return page.questions[questionIndex].options[userAnswer].isCorrect
        }

        let correctCount = pageAnswers.compactMap { $0 }.filter { $0 }.count
        let totalCount = pageAnswers.compactMap { $0 }.count

        return Button {
            selectedPageIndex = pageIndex
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Loc.StoryLab.Reading.page(pageIndex + 1, totalPages))
                        .font(.headline)

                    if totalCount > 0 {
                        Text("\(correctCount) / \(totalCount) \(Loc.Quizzes.correctAnswers)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if totalCount > 0 {
                    let percentage = totalCount > 0 ? Int((Double(correctCount) / Double(totalCount)) * 100) : 0
                    Text("\(percentage)%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            correctCount == totalCount ? Color.green :
                            (Double(correctCount) / Double(totalCount)) >= 0.7 ? Color.orange :
                            Color.red
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .clippedWithBackground(
                Color.tertiarySystemGroupedBackground,
                in: .rect(cornerRadius: 16)
            )
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func discoveredWordsSection(words: [String]) -> some View {
        CustomSectionView(header: Loc.StoryLab.Results.wordsDiscovered, hPadding: .zero) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(words.count) \(Loc.Plurals.Words.wordsCount(words.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HFlow(alignment: .top, spacing: 8) {
                    ForEach(words, id: \.self) { word in
                        Text(word)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func updateCelebrationState() {
        showConfetti = viewModel.score >= 70
    }
}

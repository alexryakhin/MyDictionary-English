//
//  StoryLabResultsView.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI
import Flow

struct StoryLabResultsView: View {
    let session: StorySession
    let story: AIStoryResponse
    let config: StoryLabConfig
    let showStreak: Bool
    let currentDayStreak: Int?
    let isPresentedModally: Bool

    @State private var showConfetti = false
    @State private var selectedPageIndex: Int?
    @State private var showStreakAnimation = false
    
    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 24) {
                // Score Summary
                scoreSummarySection
                
                // Performance Breakdown
                performanceBreakdownSection
                
                // Discovered Words
                if !session.discoveredWords.isEmpty {
                    discoveredWordsSection
                }
            }
            .padding(16)
        } navigationBar: {
            NavigationBarView(
                title: Loc.StoryLab.Results.title,
                mode: .inline,
                showsDismissButton: isPresentedModally
            )
        }
        .groupedBackgroundWithConfetti(isActive: $showConfetti)
        .overlay {
            // Streak animation overlay
            if showStreakAnimation, let streak = currentDayStreak {
                StreakProgressionAnimation(isActive: $showStreakAnimation, targetStreak: streak)
            }
        }
        .onAppear {
            // Trigger confetti if score >= 70%
            if session.score >= 70 {
                showConfetti = true
            }
            // Show streak animation if applicable
            if showStreak {
                showStreakAnimation = showStreak
            }
        }
        .sheet(item: Binding(
            get: { selectedPageIndex.map { $0 } },
            set: { selectedPageIndex = $0 }
        )) { pageIndex in
            if pageIndex < story.pages.count {
                StoryLabPageDetailView(
                    page: story.pages[pageIndex],
                    pageIndex: pageIndex,
                    session: session,
                    story: story
                )
            }
        }
    }
    
    // MARK: - Score Summary
    
    private var scoreSummarySection: some View {
        CustomSectionView(header: Loc.StoryLab.Results.summary) {
            VStack(spacing: 16) {
                // Score Circle or Progress
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(session.score) / 100)
                        .stroke(
                            session.score >= 70 ? Color.green :
                            session.score >= 50 ? Color.orange :
                            Color.red,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: session.score)

                    VStack(spacing: 4) {
                        Text("\(session.score)%")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(Loc.StoryLab.Results.score)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Stats
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text(session.correctAnswers.formatted())
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(Loc.StoryLab.Results.correctAnswers)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 4) {
                        Text(session.totalQuestions.formatted())
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
    
    // MARK: - Performance Breakdown
    
    private var performanceBreakdownSection: some View {
        CustomSectionView(
            header: Loc.Quizzes.yourResults
        ) {
            VStack(spacing: 12) {
                ForEach(Array(story.pages.enumerated()), id: \.offset) { index, page in
                    pagePerformanceRow(pageIndex: index, page: page)
                }
            }
            .padding(.bottom, 12)
        }
    }
    
    private func pagePerformanceRow(pageIndex: Int, page: AIStoryPage) -> some View {
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
                    Text(Loc.StoryLab.Reading.page(pageIndex + 1, story.pages.count))
                        .font(.headline)

                    if totalCount > 0 {
                        Text("\(correctCount) / \(totalCount) \(Loc.Quizzes.correctAnswers)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if totalCount > 0 {
                    Text("\(Int((Double(correctCount) / Double(totalCount)) * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            correctCount == totalCount ? .green :
                            (Double(correctCount) / Double(totalCount)) >= 0.7 ? .orange :
                            .red
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
    
    // MARK: - Discovered Words
    
    private var discoveredWordsSection: some View {
        CustomSectionView(
            header: Loc.StoryLab.Results.wordsDiscovered,
            hPadding: .zero
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(session.discoveredWords.count) \(Loc.Plurals.Words.wordsCount(session.discoveredWords.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HFlow(alignment: .top, spacing: 8) {
                    ForEach(Array(session.discoveredWords.sorted()), id: \.self) { word in
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
}

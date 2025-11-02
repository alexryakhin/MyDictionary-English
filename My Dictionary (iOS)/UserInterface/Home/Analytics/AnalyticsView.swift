//
//  AnalyticsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct AnalyticsView: View {
    
    @StateObject private var subscriptionService: SubscriptionService = .shared
    @StateObject private var usageTracker = TTSUsageTracker.shared
    @ObservedObject private var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    LoaderView()
                        .frame(width: 32, height: 32)
                    Text(Loc.Analytics.loadingProgressData)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    // Streak Section
                    streakSection
                    
                    // Progress Overview
                    progressOverviewSection

                    // Quiz Activity Chart
                    quizActivitySection

                    // TTS Analytics (Pro users only)
                    if SubscriptionService.shared.isProUser {
                        ttsAnalyticsSection
                    }

                    // Quiz Results Table
                    quizResultsSection

                    // Vocabulary Growth Chart
                    vocabularyGrowthSection
                }
                .padding(vertical: 12, horizontal: 16)
                .if(isPad) { view in
                    view
                        .frame(maxWidth: 550, alignment: .center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .groupedBackground()
        .navigation(title: Loc.Analytics.progress, mode: .large)
        .refreshable {
            viewModel.refreshData()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.analyticsOpened)
        }
    }
    
    // MARK: - Streak Section
    
    private var streakSection: some View {
        StreakCard(streak: viewModel.currentStreak)
    }
    
    // MARK: - TTS Analytics Section
    
    private var ttsAnalyticsSection: some View {
        CustomSectionView(header: Loc.Tts.usageStatistics) {
            TTSAnalyticsView()
        }
    }
    
    // MARK: - Quiz Activity Section
    
    private var quizActivitySection: some View {
        QuizActivityChart(
            data: viewModel.quizActivityData,
            onShowAllMonths: {
                if subscriptionService.isProUser {
                    viewModel.showAllQuizActivity()
                } else {
                    PaywallService.shared.presentPaywall(for: .advancedAnalytics)
                }
            }
        )
    }
    
    // MARK: - Progress Overview Section
    
    private var progressOverviewSection: some View {
        CustomSectionView(header: Loc.Analytics.overview) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressCard(
                        title: Loc.Words.inProgress,
                        value: "\(viewModel.progressSummary?.inProgress ?? 0)",
                        color: .orange,
                        icon: "clock"
                    )
                    ProgressCard(
                        title: Loc.Words.mastered,
                        value: "\(viewModel.progressSummary?.mastered ?? 0)",
                        color: .accent,
                        icon: "checkmark.circle"
                    )
                    ProgressCard(
                        title: Loc.Words.needsReview,
                        value: "\(viewModel.progressSummary?.needsReview ?? 0)",
                        color: .red,
                        icon: "exclamationmark.triangle"
                    )
                }
                HStack(spacing: 12) {
                    StatCard(
                        title: Loc.Analytics.practiceTime,
                        value: viewModel.totalPracticeTimeFormatted,
                        icon: "clock.fill"
                    )

                    StatCard(
                        title: Loc.Analytics.accuracy,
                        value: viewModel.averageAccuracyFormatted,
                        icon: "target"
                    )

                    StatCard(
                        title: Loc.Analytics.sessions,
                        value: "\(viewModel.progressSummary?.totalSessions ?? 0)",
                        icon: "play.circle"
                    )
                }
                .reservedForPro(message: Loc.Subscription.ProUpgrade.upgradeToProProgressDetails)
            }
        }
    }
    
    // MARK: - Quiz Results Section
    
    private var quizResultsSection: some View {
        CustomSectionView(header: Loc.Analytics.recentQuizResults) {
            if viewModel.quizSessions.isEmpty {
                ContentUnavailableView(
                    Loc.Analytics.noQuizResultsYet,
                    systemImage: "chart.bar",
                    description: Text(Loc.Analytics.completeFirstQuizResults)
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.quizSessions.prefix(3)) { session in
                        QuizResultRow(session: session)
                    }
                }
            }
        } trailingContent: {
            HeaderButton(Loc.Analytics.allResults, size: .small) {
                if subscriptionService.isProUser {
                    viewModel.output.send(.showQuizResultsList)
                } else {
                    PaywallService.shared.presentPaywall(for: .advancedAnalytics)
                }
            }
        }
    }
    
    // MARK: - Vocabulary Growth Section
    
    private var vocabularyGrowthSection: some View {
        CustomSectionView(header: Loc.Analytics.vocabularyGrowth) {
            if viewModel.vocabularyGrowthData.isEmpty {
                ContentUnavailableView(
                    Loc.Analytics.noGrowthDataYet,
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text(Loc.Analytics.completeQuizzesGrowthData)
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.Analytics.lastTimePeriod(viewModel.selectedTimePeriod.displayName.lowercased()))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VocabularyLineChart(data: viewModel.vocabularyGrowthData)
                        .frame(height: 200)
                }
                .reservedForPro(message: Loc.Subscription.ProUpgrade.upgradeToProVocabularyGrowth)
            }
        } trailingContent: {
            if subscriptionService.isProUser {
                HeaderButtonMenu(
                    viewModel.selectedTimePeriod.displayName,
                    size: .small
                ) {
                    Picker(Loc.Subscription.ProUpgrade.timePeriod, selection: $viewModel.selectedTimePeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
        }
    }
}

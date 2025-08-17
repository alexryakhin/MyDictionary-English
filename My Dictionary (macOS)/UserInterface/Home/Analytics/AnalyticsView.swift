//
//  AnalyticsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct AnalyticsView: View {
    
    @StateObject private var subscriptionService: SubscriptionService = .shared
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showingQuizResults: Bool = false

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(Loc.Analytics.loadingProgressData.localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    // Progress Overview
                    progressOverviewSection

                    // Quiz Results Table
                    quizResultsSection

                    // Vocabulary Growth Chart
                    vocabularyGrowthSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
        .groupedBackground()
        .navigationTitle(Loc.Analytics.progress.localized)
        .refreshable {
            viewModel.refreshData()
        }
        .sheet(isPresented: $showingQuizResults) {
            QuizResultsList.ContentView(quizSessions: viewModel.quizSessions)
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.analyticsOpened)
            viewModel.loadData()
        }
    }
    
    // MARK: - Progress Overview Section
    
    private var progressOverviewSection: some View {
        CustomSectionView(header: Loc.Analytics.overview.localized) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressCard(
                        title: Loc.Words.inProgress.localized,
                        value: "\(viewModel.progressSummary?.inProgress ?? 0)",
                        color: .orange,
                        icon: "clock"
                    )
                    ProgressCard(
                        title: Loc.Words.mastered.localized,
                        value: "\(viewModel.progressSummary?.mastered ?? 0)",
                        color: .accent,
                        icon: "checkmark.circle"
                    )
                    ProgressCard(
                        title: Loc.Words.needsReview.localized,
                        value: "\(viewModel.progressSummary?.needsReview ?? 0)",
                        color: .red,
                        icon: "exclamationmark.triangle"
                    )
                }
                HStack(spacing: 12) {
                    StatCard(
                        title: Loc.Analytics.practiceTime.localized,
                        value: viewModel.totalPracticeTimeFormatted,
                        icon: "clock.fill"
                    )

                    StatCard(
                        title: Loc.Analytics.accuracy.localized,
                        value: viewModel.averageAccuracyFormatted,
                        icon: "target"
                    )

                    StatCard(
                        title: Loc.Analytics.sessions.localized,
                        value: "\(viewModel.progressSummary?.totalSessions ?? 0)",
                        icon: "play.circle"
                    )
                }
                .reservedForPro(message: Loc.ProUpgrade.upgradeToProProgressDetails.localized)
            }
        }
    }
    
    // MARK: - Quiz Results Section
    
    private var quizResultsSection: some View {
        CustomSectionView(header: Loc.Analytics.recentQuizResults.localized) {
            if viewModel.quizSessions.isEmpty {
                ContentUnavailableView(
                    Loc.Analytics.noQuizResultsYet.localized,
                    systemImage: "chart.bar",
                    description: Text(Loc.Analytics.completeFirstQuizResults.localized)
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.quizSessions.prefix(3)) { session in
                        QuizResultRow(session: session)
                    }
                }
            }
        } trailingContent: {
            HeaderButton(Loc.Analytics.allResults.localized, size: .small) {
                if subscriptionService.isProUser {
                    showingQuizResults = true
                } else {
                    PaywallService.shared.isShowingPaywall = true
                }
            }
        }
    }
    
    // MARK: - Vocabulary Growth Section
    
    private var vocabularyGrowthSection: some View {
        CustomSectionView(header: Loc.Analytics.vocabularyGrowth.localized) {
            if viewModel.vocabularyGrowthData.isEmpty {
                ContentUnavailableView(
                    Loc.Analytics.noGrowthDataYet.localized,
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text(Loc.Analytics.completeQuizzesGrowthData.localized)
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Loc.Analytics.lastTimePeriod.localized(viewModel.selectedTimePeriod.displayName.lowercased()))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VocabularyLineChart(data: viewModel.vocabularyGrowthData)
                        .frame(height: 200)
                }
                .reservedForPro(message: Loc.ProUpgrade.upgradeToProVocabularyGrowth.localized)
            }
        } trailingContent: {
            if subscriptionService.isProUser {
                HeaderButtonMenu(
                    viewModel.selectedTimePeriod.displayName,
                    size: .small
                ) {
                    Picker(Loc.ProUpgrade.timePeriod.localized, selection: $viewModel.selectedTimePeriod) {
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

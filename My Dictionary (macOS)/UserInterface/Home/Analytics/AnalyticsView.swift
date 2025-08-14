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
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading progress data...")
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
        .navigationTitle("Progress")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Time period picker for vocabulary growth
                if subscriptionService.isProUser {
                    Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    .help("Select Time Period")
                }
                
                // Refresh button
                Button {
                    viewModel.refreshData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh Data")
            }
        }
        .refreshable {
            viewModel.refreshData()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.analyticsOpened)
            viewModel.loadData()
        }
    }
    
    // MARK: - Progress Overview Section
    
    private var progressOverviewSection: some View {
        CustomSectionView(header: "Overview") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ProgressCard(
                        title: "In Progress",
                        value: "\(viewModel.progressSummary?.inProgress ?? 0)",
                        color: .orange,
                        icon: "clock"
                    )
                    ProgressCard(
                        title: "Mastered",
                        value: "\(viewModel.progressSummary?.mastered ?? 0)",
                        color: .accent,
                        icon: "checkmark.circle"
                    )
                    ProgressCard(
                        title: "Need Review",
                        value: "\(viewModel.progressSummary?.needsReview ?? 0)",
                        color: .red,
                        icon: "exclamationmark.triangle"
                    )
                }
                HStack(spacing: 12) {
                    StatCard(
                        title: "Practice Time",
                        value: viewModel.totalPracticeTimeFormatted,
                        icon: "clock.fill"
                    )

                    StatCard(
                        title: "Accuracy",
                        value: viewModel.averageAccuracyFormatted,
                        icon: "target"
                    )

                    StatCard(
                        title: "Sessions",
                        value: "\(viewModel.progressSummary?.totalSessions ?? 0)",
                        icon: "play.circle"
                    )
                }
                .reservedForPro(message: "Upgrade to Pro to see full progress details.")
            }
        }
    }
    
    // MARK: - Quiz Results Section
    
    private var quizResultsSection: some View {
        CustomSectionView(header: "Recent Quiz Results") {
            if viewModel.quizSessions.isEmpty {
                ContentUnavailableView(
                    "No Quiz Results Yet",
                    systemImage: "chart.bar",
                    description: Text("Complete your first quiz to see results here")
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.quizSessions.prefix(3)) { session in
                        QuizResultRow(session: session)
                    }
                }
            }
        } trailingContent: {
            HeaderButton("View All", size: .small) {
                if subscriptionService.isProUser {
                    viewModel.output.send(.showQuizResultsList)
                } else {
                    PaywallService.shared.isShowingPaywall = true
                }
            }
        }
    }
    
    // MARK: - Vocabulary Growth Section
    
    private var vocabularyGrowthSection: some View {
        CustomSectionView(header: "Vocabulary Growth") {
            if viewModel.vocabularyGrowthData.isEmpty {
                ContentUnavailableView(
                    "No Growth Data Yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Complete quizzes to see your vocabulary growth over time")
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last \(viewModel.selectedTimePeriod.displayName.lowercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VocabularyLineChart(data: viewModel.vocabularyGrowthData)
                        .frame(height: 200)
                }
                .reservedForPro(message: "Upgrade to Pro to see full vocabulary growth details.")
            }
        }
    }
}

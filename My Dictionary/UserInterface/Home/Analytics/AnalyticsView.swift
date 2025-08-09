//
//  AnalyticsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct AnalyticsView: View {
    
    @ObservedObject var viewModel: AnalyticsViewModel
    
    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading progress data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 24) {
                    // Progress Overview
                    progressOverviewSection

                    // Quiz Results Table
                    quizResultsSection

                    // Vocabulary Growth Chart
                    vocabularyGrowthSection
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigation(title: "Progress", mode: .large)
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
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ProgressCard(
                    title: "In Progress",
                    value: "\(viewModel.progressSummary?.inProgress ?? 0)",
                    color: .blue,
                    icon: "clock"
                )

                ProgressCard(
                    title: "Mastered",
                    value: "\(viewModel.progressSummary?.mastered ?? 0)",
                    color: .green,
                    icon: "checkmark.circle"
                )

                ProgressCard(
                    title: "Need Review",
                    value: "\(viewModel.progressSummary?.needsReview ?? 0)",
                    color: .orange,
                    icon: "exclamationmark.triangle"
                )

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
            HeaderButton(text: "View All") {
                viewModel.output.send(.showQuizResultsDetail)
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
                        .foregroundColor(.secondary)

                    VocabularyLineChart(data: viewModel.vocabularyGrowthData)
                        .frame(height: 200)
                }
            }
        } trailingContent: {
            Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.menu)
            .buttonStyle(.bordered)
            .clipShape(Capsule())
        }
    }
}

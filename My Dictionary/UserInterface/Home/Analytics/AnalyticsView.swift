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
                LazyVStack(spacing: 16) {
                    // Progress Overview
                    progressOverviewSection

                    // Quiz Results Table
                    quizResultsSection

                    // Vocabulary Growth Chart
                    vocabularyGrowthSection
                }
                .padding(16)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
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
        .clippedWithPaddingAndBackground(Color(.secondarySystemGroupedBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quiz Results Section
    
    private var quizResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Quiz Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if viewModel.quizSessions.count > 3 {
                    Button {
                        viewModel.output.send(.showQuizResultsDetail)
                    } label: {
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
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
        }
        .clippedWithPaddingAndBackground(Color(.secondarySystemGroupedBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Vocabulary Growth Section
    
    private var vocabularyGrowthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Vocabulary Growth")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Time Period", selection: $viewModel.selectedTimePeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.menu)
            }
            
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
        }
        .clippedWithPaddingAndBackground(Color(.secondarySystemGroupedBackground))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

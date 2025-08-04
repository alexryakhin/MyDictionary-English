//
//  AnalyticsContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AnalyticsContentView: View {
    
    @StateObject private var viewModel = AnalyticsViewModel()
    
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
        .navigationTitle("Progress")
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
        .clippedWithPaddingAndBackground()
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
                    NavigationLink {
                        QuizResultsDetailView()
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
        .clippedWithPaddingAndBackground()
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
        .clippedWithPaddingAndBackground()
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Supporting Views

struct ProgressCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(padding: 12, color: color.opacity(0.1))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(color: Color(.tertiarySystemGroupedBackground))
    }
}

struct QuizResultRow: View {
    let session: CDQuizSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text((session.quizType ?? "").capitalized)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(session.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.score)) pts")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("\(Int(session.accuracy * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

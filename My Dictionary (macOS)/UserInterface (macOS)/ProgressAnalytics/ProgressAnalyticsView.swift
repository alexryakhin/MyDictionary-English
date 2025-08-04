//
//  ProgressAnalyticsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct ProgressAnalyticsView: View {
    
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading progress data...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(100)
            } else {
                LazyVStack(spacing: 24) {
                    // Progress Overview
                    progressOverviewSection
                    
                    // Quiz Results Table
                    quizResultsSection
                    
                    // Vocabulary Growth Chart
                    vocabularyGrowthSection
                }
                .padding(24)
            }
        }
        .background(Color(.windowBackgroundColor))
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
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
            }
            
            // Stats Row
            HStack(spacing: 16) {
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
        .padding(20)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                            .foregroundStyle(.blue)
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
        .padding(20)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .pickerStyle(.segmented)
                .frame(width: 200)
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
                        .foregroundStyle(.secondary)
                    
                    VocabularyLineChart(data: viewModel.vocabularyGrowthData)
                        .frame(height: 200)
                }
            }
        }
        .padding(20)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuizResultRow: View {
    let session: CDQuizSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.quizType?.capitalized ?? "Quiz")
                    .font(.headline)
                    .fontWeight(.medium)
                
                if let date = session.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.score)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
                
                Text("\(session.correctAnswers)/\(session.totalWords)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var scoreColor: Color {
        let accuracy = session.accuracy
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.6 { return .orange }
        return .red
    }
}

#Preview {
    ProgressAnalyticsView()
} 

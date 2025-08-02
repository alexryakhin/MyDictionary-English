//
//  QuizResultsDetailView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct QuizResultsDetailView: View {
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            if viewModel.quizSessions.isEmpty {
                ContentUnavailableView(
                    "No Quiz Results Yet",
                    systemImage: "chart.bar",
                    description: Text("Complete your first quiz to see detailed results here")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.quizSessions) { session in
                    QuizResultDetailRow(session: session)
                }
            }
        }
        .navigationTitle("Quiz Results")
        .onAppear {
            AnalyticsService.shared.logEvent(.quizResultsDetailOpened)
            viewModel.loadData()
        }
    }
}

struct QuizResultDetailRow: View {
    let session: CDQuizSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and quiz type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.quizType?.capitalized ?? "Quiz")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let date = session.date {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Score badge
                Text("\(session.score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(scoreColor.gradient)
                    .clipShape(Capsule())
            }
            
            // Stats row
            HStack(spacing: 16) {
                StatItem(
                    title: "Accuracy",
                    value: "\(Int(session.accuracy * 100))%",
                    icon: "target",
                    color: .blue
                )
                
                StatItem(
                    title: "Correct",
                    value: "\(session.correctAnswers)/\(session.totalWords)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatItem(
                    title: "Duration",
                    value: formatDuration(session.duration),
                    icon: "clock",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private var scoreColor: Color {
        let accuracy = session.accuracy
        if accuracy >= 0.8 { return .green }
        if accuracy >= 0.6 { return .orange }
        return .red
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    QuizResultsDetailView()
} 

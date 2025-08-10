//
//  AnalyticsContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct AnalyticsContentView: View {

    @ObservedObject var viewModel: AnalyticsViewModel

    init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        AnalyticsView(viewModel: viewModel)
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
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(color.opacity(0.15), cornerRadius: 16)
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
                .foregroundStyle(.accent)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clippedWithPaddingAndBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 16)
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
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.score)) pts")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.accent)
                
                Text("\(Int(session.accuracy * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .clippedWithBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 12)
    }
}

//
//  SharedWordDifficultyStatsView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SharedWordDifficultyStatsView: View {
    let word: SharedWord
    let dictionaryId: String
    @StateObject private var dictionaryService = DictionaryService.shared
    @State private var difficultyStats: [String: Int] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerSection
            
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else {
                statsContent
            }
        }
        .padding(16)
        .onAppear {
            AnalyticsService.shared.logEvent(.sharedWordStatsViewed)
            loadDifficultyStats()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Difficulty Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("How other users rate this word")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading difficulty stats...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.red)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                loadDifficultyStats()
            }
            .font(.caption)
            .foregroundStyle(.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        VStack(spacing: 16) {
            // Summary stats
            summaryStatsSection
            
            // Individual user ratings
            if !difficultyStats.isEmpty {
                userRatingsSection
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Summary Stats
    
    private var summaryStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(
                    title: "Total Ratings",
                    value: "\(difficultyStats.count)",
                    icon: "person.2.fill"
                )
                
                StatCard(
                    title: "Average Difficulty",
                    value: String(format: "%.1f", word.averageDifficulty),
                    icon: "chart.bar.fill"
                )
            }
            
            HStack {
                StatCard(
                    title: "Likes",
                    value: "\(word.likeCount)",
                    icon: "heart.fill"
                )
                
                StatCard(
                    title: "Added By",
                    value: word.addedByShortText,
                    icon: "person.circle.fill"
                )
            }
        }
    }
    
    // MARK: - User Ratings Section
    
    private var userRatingsSection: some View {
        VStack(spacing: 12) {
            Text("Individual Ratings")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(difficultyStats.keys.sorted()), id: \.self) { userEmail in
                    UserDifficultyRow(
                        userEmail: userEmail,
                        difficulty: difficultyStats[userEmail] ?? 0
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No difficulty ratings yet")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Be the first to rate this word's difficulty")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadDifficultyStats() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let stats = try await dictionaryService.getDifficultyStats(for: word.id, in: dictionaryId)
                await MainActor.run {
                    self.difficultyStats = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Stat Card

extension SharedWordDifficultyStatsView {
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
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - User Difficulty Row

struct UserDifficultyRow: View {
    let userEmail: String
    let difficulty: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(userEmail)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(getDifficultyDisplayName())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            DifficultyBadge(difficulty: difficulty)
        }
        .padding(12)
        .background(.background)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func getDifficultyDisplayName() -> String {
        switch difficulty {
        case 0: return "New"
        case 1: return "In Progress"
        case 2: return "Needs Review"
        case 3: return "Mastered"
        default: return "New"
        }
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Int
    
    var body: some View {
        Text(getDifficultyDisplayName())
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(getDifficultyColor().opacity(0.2))
            .foregroundStyle(getDifficultyColor())
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    private func getDifficultyDisplayName() -> String {
        switch difficulty {
        case 0: return "New"
        case 1: return "In Progress"
        case 2: return "Needs Review"
        case 3: return "Mastered"
        default: return "New"
        }
    }
    
    private func getDifficultyColor() -> Color {
        switch difficulty {
        case 0: return .blue
        case 1: return .orange
        case 2: return .red
        case 3: return .accent
        default: return .blue
        }
    }
}

#Preview {
    let sampleWord = SharedWord(
        id: "1",
        wordItself: "Example",
        definition: "A thing characteristic of its kind",
        partOfSpeech: "noun",
        phonetic: "ɪɡˈzæmpəl",
        examples: ["This is an example sentence."],
        languageCode: "en",
        addedByEmail: "user@example.com",
        addedByDisplayName: "John Doe",
        likes: ["user1@example.com": true, "user2@example.com": false],
        difficulties: ["user1@example.com": 2, "user2@example.com": 1]
    )
    
    SharedWordDifficultyStatsView(
        word: sampleWord,
        dictionaryId: "sample-dict-id"
    )
}

//
//  TTSUsageTracker.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine

@MainActor
final class TTSUsageTracker: ObservableObject {

    static let shared = TTSUsageTracker()

    @Published var usageStats = TTSUsageStats()

    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadUsageStats()
    }

    // MARK: - Usage Tracking

    func trackTTSUsage(text: String, provider: TTSProvider, language: String, voice: String? = nil) {
        let characterCount = text.count

        // Update total characters
        usageStats.totalCharacters += characterCount

        // Update provider-specific stats
        switch provider {
        case .google:
            usageStats.googleCharacters += characterCount
        case .speechify:
            usageStats.speechifyCharacters += characterCount
        }

        // Update session count
        usageStats.totalSessions += 1

        // Update language stats
        if let existingCount = usageStats.languageUsage[language] {
            usageStats.languageUsage[language] = existingCount + characterCount
        } else {
            usageStats.languageUsage[language] = characterCount
        }

        // Update voice stats (for Speechify)
        if let voice = voice {
            if let existingCount = usageStats.voiceUsage[voice] {
                usageStats.voiceUsage[voice] = existingCount + characterCount
            } else {
                usageStats.voiceUsage[voice] = characterCount
            }
        }

        // Update last usage time
        usageStats.lastUsed = Date()

        // Save stats
        saveUsageStats()

        // Log for analytics
        AnalyticsService.shared.logEvent(.wordPlayed)
    }

    func trackTTSDuration(duration: TimeInterval) {
        usageStats.totalDuration += duration
        saveUsageStats()
    }

    // MARK: - Statistics

    var totalCharactersFormatted: String {
        return formatNumber(usageStats.totalCharacters)
    }

    var totalSessionsFormatted: String {
        return formatNumber(usageStats.totalSessions)
    }

    var totalDurationFormatted: String {
        let hours = Int(usageStats.totalDuration) / 3600
        let minutes = Int(usageStats.totalDuration) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var favoriteVoice: String {
        let sortedVoices = usageStats.voiceUsage.sorted { $0.value > $1.value }
        return sortedVoices.first?.key ?? "None"
    }

    var favoriteLanguage: String {
        let sortedLanguages = usageStats.languageUsage.sorted { $0.value > $1.value }
        return sortedLanguages.first?.key ?? "Unknown"
    }

    var timeSaved: String {
        // Estimate time saved based on reading speed (average 200 words per minute)
        let wordsPerMinute: Double = 200
        let charactersPerWord: Double = 5 // Average
        let totalWords = Double(usageStats.totalCharacters) / charactersPerWord
        let timeToRead = totalWords / wordsPerMinute

        let hours = Int(timeToRead) / 60
        let minutes = Int(timeToRead) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var providerUsagePercentage: Double {
        guard usageStats.totalCharacters > 0 else { return 0 }
        return Double(usageStats.speechifyCharacters) / Double(usageStats.totalCharacters) * 100
    }

    // MARK: - Data Management

    private func loadUsageStats() {
        if let data = userDefaults.data(forKey: "tts_usage_stats"),
           let stats = try? JSONDecoder().decode(TTSUsageStats.self, from: data) {
            usageStats = stats
        }
    }

    private func saveUsageStats() {
        if let data = try? JSONEncoder().encode(usageStats) {
            userDefaults.set(data, forKey: "tts_usage_stats")
        }
    }

    // MARK: - Helper Methods

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }

    func resetStats() {
        usageStats = TTSUsageStats()
        saveUsageStats()
    }

    func exportStats() -> String {
        let stats = """
        TTS Usage Statistics
        
        Total Characters: \(totalCharactersFormatted)
        Total Sessions: \(totalSessionsFormatted)
        Total Duration: \(totalDurationFormatted)
        Time Saved: \(timeSaved)
        
        Provider Usage:
        - Google TTS: \(formatNumber(usageStats.googleCharacters)) characters
        - Speechify: \(formatNumber(usageStats.speechifyCharacters)) characters
        - Premium Usage: \(String(format: "%.1f", providerUsagePercentage))%
        
        Favorite Voice: \(favoriteVoice)
        Favorite Language: \(favoriteLanguage)
        
        Last Used: \(usageStats.lastUsed?.formatted() ?? "Never")
        """

        return stats
    }
}

// MARK: - Data Models

struct TTSUsageStats: Codable {
    var totalCharacters: Int = 0
    var totalSessions: Int = 0
    var totalDuration: TimeInterval = 0
    var googleCharacters: Int = 0
    var speechifyCharacters: Int = 0
    var languageUsage: [String: Int] = [:]
    var voiceUsage: [String: Int] = [:]
    var lastUsed: Date?

    // Weekly/Monthly tracking
    var weeklyCharacters: Int = 0
    var monthlyCharacters: Int = 0
    var weeklySessions: Int = 0
    var monthlySessions: Int = 0
}

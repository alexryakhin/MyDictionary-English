//
//  AnalyticsViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

enum TimePeriod: CaseIterable {
    case week
    case month
    case year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}

final class AnalyticsViewModel: BaseViewModel {
    
    @Published private(set) var progressSummary: ProgressSummary?
    @Published private(set) var quizSessions: [CDQuizSession] = []
    @Published private(set) var isLoading = false
    @Published var selectedTimePeriod: TimePeriod = .month
    
    private let quizAnalyticsService = QuizAnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        DispatchQueue.main.async { [weak self] in
            self?.progressSummary = self?.quizAnalyticsService.getProgressSummary()
            self?.quizSessions = self?.quizAnalyticsService.getQuizSessions() ?? []
            self?.isLoading = false
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    // MARK: - Computed Properties
    
    var totalPracticeTimeFormatted: String {
        guard let summary = progressSummary else { return "0 min" }
        let minutes = Int(summary.totalPracticeTime / 60)
        return "\(minutes) min"
    }
    
    var averageAccuracyFormatted: String {
        guard let summary = progressSummary else { return "0%" }
        return "\(Int(summary.averageAccuracy * 100))%"
    }
    
    var vocabularyGrowthData: [VocabularyLineChart.Model] {
        // Get actual quiz sessions and words to create realistic growth data
        let sessions = quizAnalyticsService.getQuizSessions(limit: 100)
        let words = quizAnalyticsService.getAllWords()
        let calendar = Calendar.current
        let today = Date()
        var data: [VocabularyLineChart.Model] = []
        
        print("📊 Chart Debug: Found \(words.count) words and \(sessions.count) quiz sessions")
        
        // Create data for selected time period
        for i in 0..<selectedTimePeriod.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Count words that were added on or before this date
                let wordsAddedByDate = words.filter { word in
                    guard let wordDate = word.timestamp else { return false }
                    return calendar.compare(wordDate, to: date, toGranularity: .day) != .orderedDescending
                }.count
                
                // Count sessions on this date
                let sessionsOnDate = sessions.filter { session in
                    guard let sessionDate = session.date else { return false }
                    return calendar.isDate(sessionDate, inSameDayAs: date)
                }
                
                // Calculate words learned from sessions on this date
                let wordsLearnedFromSessions = sessionsOnDate.reduce(0) { total, session in
                    total + Int(session.totalWords)
                }
                
                // Total words for this date = words added by this date + words learned from sessions
                let totalWords = wordsAddedByDate + wordsLearnedFromSessions
                
                data.append(VocabularyLineChart.Model(date: date, count: totalWords))
                
                if wordsAddedByDate > 0 {
                    print("📅 \(date.formatted(date: .abbreviated, time: .omitted)): Added \(wordsAddedByDate) words")
                }
            }
        }
        
        // If no real data, create mock data based on current vocabulary size
        if data.allSatisfy({ $0.count == 0 }) {
            print("📊 Chart Debug: No real data found, using mock data")
            let currentSize = progressSummary?.vocabularySize ?? 0
            for i in 0..<selectedTimePeriod.days {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let mockSize = max(0, currentSize - (selectedTimePeriod.days - i) * (currentSize / selectedTimePeriod.days))
                    data.append(VocabularyLineChart.Model(date: date, count: mockSize))
                }
            }
        }
        
        print("📊 Chart Debug: Final data points: \(data.count)")
        return data
    }
} 
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
    
    enum Output {
        case showQuizResultsDetail
    }

    var output = PassthroughSubject<Output, Never>()
    
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
        guard let summary = progressSummary else { return "0min" }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        
        let timeInterval = summary.totalPracticeTime
        return formatter.string(from: timeInterval) ?? "0min"
    }
    
    var averageAccuracyFormatted: String {
        guard let summary = progressSummary else { return "0%" }
        return "\(Int(summary.averageAccuracy * 100))%"
    }
    
    var vocabularyGrowthData: [VocabularyLineChart.Model] {
        // Get words to create vocabulary growth data
        let words = quizAnalyticsService.getAllWords()
        let calendar = Calendar.current
        let today = Date()
        var data: [VocabularyLineChart.Model] = []
        
        // Create data for selected time period
        for i in 0..<selectedTimePeriod.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Count words that were added on or before this date
                let wordsAddedByDate = words.filter { word in
                    guard let wordDate = word.timestamp else { return false }
                    return calendar.compare(wordDate, to: date, toGranularity: .day) != .orderedDescending
                }.count
                
                data.append(VocabularyLineChart.Model(date: date, count: wordsAddedByDate))
            }
        }
        
        // If no real data, create mock data based on current vocabulary size
        if data.allSatisfy({ $0.count == 0 }) {
            let currentSize = progressSummary?.vocabularySize ?? 0
            for i in 0..<selectedTimePeriod.days {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let mockSize = max(0, currentSize - (selectedTimePeriod.days - i) * (currentSize / selectedTimePeriod.days))
                    data.append(VocabularyLineChart.Model(date: date, count: mockSize))
                }
            }
        }
        
        return data
    }
} 
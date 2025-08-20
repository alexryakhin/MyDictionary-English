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
        case .week: return Loc.TimePeriod.week.localized
        case .month: return Loc.TimePeriod.month.localized
        case .year: return Loc.TimePeriod.year.localized
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
        setupReactiveUpdates()
    }
    
    private func setupReactiveUpdates() {
        // Listen to Core Data changes
        CoreDataService.shared.dataUpdatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
        
        // Listen to shared dictionary changes with debouncing to prevent excessive refreshes
        DictionaryService.shared.$sharedWords
            .debounce(for: .seconds(1.0), scheduler: DispatchQueue.main)
            .removeDuplicates() // Only trigger if the actual data changed
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        Task { @MainActor in
            isLoading = true
            progressSummary = quizAnalyticsService.getProgressSummary()
            quizSessions = quizAnalyticsService.getQuizSessions()
            isLoading = false
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
        let words = quizAnalyticsService.getAllItems()
        let calendar = Calendar.current
        let today = Date()
        var data: [VocabularyLineChart.Model] = []
        
        // Create data for selected time period
        for i in 0..<selectedTimePeriod.days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Count words that were added on or before this date
                let wordsAddedByDate = words.filter { word in
                    return calendar.compare(
                        word.quiz_timestamp,
                        to: date,
                        toGranularity: .day
                    ) != .orderedDescending
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

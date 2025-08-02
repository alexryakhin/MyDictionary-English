//
//  AnalyticsViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

final class AnalyticsViewModel: BaseViewModel {
    
    @Published private(set) var progressSummary: ProgressSummary?
    @Published private(set) var quizSessions: [CDQuizSession] = []
    @Published private(set) var isLoading = false
    
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
    
    var vocabularyGrowthData: [(Date, Int)] {
        // Mock data for now - will be implemented with real data
        let calendar = Calendar.current
        let today = Date()
        var data: [(Date, Int)] = []
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let wordCount = max(0, (progressSummary?.vocabularySize ?? 0) - (30 - i) * 2)
                data.append((date, wordCount))
            }
        }
        
        return data.reversed()
    }
} 
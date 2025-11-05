//
//  MusicSpacedReviewService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

/// Service for managing spaced repetition scheduling for music quizzes
/// Uses Anki-style spaced repetition algorithm
final class MusicSpacedReviewService {
    
    static let shared = MusicSpacedReviewService()
    
    private let coreDataService = CoreDataService.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save quiz performance to CoreData
    /// - Parameters:
    ///   - songId: The song ID
    ///   - quizItemId: The quiz item ID
    ///   - isCorrect: Whether the answer was correct
    ///   - timeSpent: Time spent on the question
    func saveQuizPerformance(
        songId: String,
        quizItemId: String,
        isCorrect: Bool,
        timeSpent: TimeInterval
    ) async throws {
        let context = coreDataService.context
        
        try await context.perform {
            let entity = CDMusicQuizPerformance(context: context)
            entity.id = UUID()
            entity.songId = songId
            entity.quizItemId = quizItemId
            entity.isCorrect = isCorrect
            entity.answeredAt = Date()
            entity.timeSpent = timeSpent
            
            try context.save()
        }
    }
    
    /// Get quiz items due for review
    /// - Parameter songId: Optional song ID to filter by
    /// - Returns: Array of quiz item IDs that are due for review
    func getItemsDueForReview(songId: String? = nil) async -> [String] {
        let context = coreDataService.context
        
        return await context.perform {
            let fetchRequest = CDMusicQuizPerformance.fetchRequest()
            
            if let songId = songId {
                fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
            }
            
            guard let performances = try? context.fetch(fetchRequest) else {
                return []
            }
            
            // Group by quiz item ID and calculate next review date
            var itemSchedules: [String: ReviewSchedule] = [:]
            
            for performance in performances {
                let itemId = performance.quizItemId ?? ""
                guard !itemId.isEmpty else { continue }
                
                if var schedule = itemSchedules[itemId] {
                    // Update schedule based on performance
                    schedule.update(wasCorrect: performance.isCorrect, answeredAt: performance.answeredAt ?? Date())
                    itemSchedules[itemId] = schedule
                } else {
                    // Create new schedule
                    var schedule = ReviewSchedule(itemId: itemId)
                    schedule.update(wasCorrect: performance.isCorrect, answeredAt: performance.answeredAt ?? Date())
                    itemSchedules[itemId] = schedule
                }
            }
            
            // Filter items that are due for review
            let now = Date()
            return itemSchedules.compactMap { itemId, schedule in
                if schedule.nextReviewDate <= now {
                    return itemId
                }
                return nil
            }
        }
    }
    
    /// Calculate next review date using Anki-style algorithm
    /// - Parameters:
    ///   - itemId: The quiz item ID
    ///   - wasCorrect: Whether the last answer was correct
    /// - Returns: Next review date
    func calculateNextReviewDate(itemId: String, wasCorrect: Bool) async -> Date {
        let context = coreDataService.context
        
        return await context.perform {
            let fetchRequest = CDMusicQuizPerformance.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "quizItemId == %@", itemId)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "answeredAt", ascending: false)]
            
            guard let performances = try? context.fetch(fetchRequest) else {
                // First time - review in 1 day
                return Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            }
            
            // Count consecutive correct answers
            var consecutiveCorrect = 0
            for performance in performances {
                if performance.isCorrect {
                    consecutiveCorrect += 1
                } else {
                    break
                }
            }
            
            // Anki-style interval calculation
            let interval: Int
            if wasCorrect {
                if consecutiveCorrect == 0 {
                    interval = 1 // First correct - review in 1 day
                } else if consecutiveCorrect == 1 {
                    interval = 3 // Second correct - review in 3 days
                } else if consecutiveCorrect == 2 {
                    interval = 7 // Third correct - review in 1 week
                } else {
                    // Exponential backoff: 1 day, 3 days, 1 week, 2 weeks, 1 month, etc.
                    let baseInterval = 7 * Int(pow(2.0, Double(consecutiveCorrect - 2)))
                    interval = min(baseInterval, 180) // Cap at 6 months
                }
            } else {
                // Wrong answer - reset to 1 day
                interval = 1
            }
            
            return Calendar.current.date(byAdding: .day, value: interval, to: Date()) ?? Date()
        }
    }
    
    /// Get review statistics for a song
    /// - Parameter songId: The song ID
    /// - Returns: Review statistics
    func getReviewStatistics(songId: String) async -> ReviewStatistics {
        let context = coreDataService.context
        
        return await context.perform {
            let fetchRequest = CDMusicQuizPerformance.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "songId == %@", songId)
            
            guard let performances = try? context.fetch(fetchRequest) else {
                return ReviewStatistics(
                    totalQuestions: 0,
                    correctAnswers: 0,
                    averageTime: 0,
                    lastReviewed: nil
                )
            }
            
            let totalQuestions = performances.count
            let correctAnswers = performances.filter { $0.isCorrect }.count
            let totalTime = performances.reduce(0.0) { $0 + $1.timeSpent }
            let averageTime = totalQuestions > 0 ? totalTime / Double(totalQuestions) : 0
            let lastReviewed = performances.max(by: { ($0.answeredAt ?? Date.distantPast) < ($1.answeredAt ?? Date.distantPast) })?.answeredAt
            
            return ReviewStatistics(
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                averageTime: averageTime,
                lastReviewed: lastReviewed
            )
        }
    }
}

// MARK: - Supporting Types

struct ReviewSchedule {
    let itemId: String
    var consecutiveCorrect: Int = 0
    var nextReviewDate: Date = Date()
    var lastReviewed: Date = Date()
    
    mutating func update(wasCorrect: Bool, answeredAt: Date) {
        lastReviewed = answeredAt
        
        if wasCorrect {
            consecutiveCorrect += 1
        } else {
            consecutiveCorrect = 0
        }
        
        // Calculate next review date
        let interval: Int
        if consecutiveCorrect == 0 {
            interval = 1
        } else if consecutiveCorrect == 1 {
            interval = 1
        } else if consecutiveCorrect == 2 {
            interval = 3
        } else if consecutiveCorrect == 3 {
            interval = 7
        } else {
            let baseInterval = 7 * Int(pow(2.0, Double(consecutiveCorrect - 3)))
            interval = min(baseInterval, 180)
        }
        
        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: answeredAt) ?? answeredAt
    }
}

struct ReviewStatistics {
    let totalQuestions: Int
    let correctAnswers: Int
    let averageTime: TimeInterval
    let lastReviewed: Date?
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0.0 }
        return Double(correctAnswers) / Double(totalQuestions)
    }
}


//
//  AnalyticsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Foundation
import Combine

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func logEvent(_ event: AnalyticsEvent) {
        print("🔹 Analytics log event: \(event.rawValue)")
        
        // Here you can add actual analytics implementation
        // For example: Firebase Analytics, Mixpanel, etc.
    }
}

// MARK: - Quiz Analytics Service

final class QuizAnalyticsService {
    static let shared = QuizAnalyticsService()
    
    private let coreDataService = ServiceManager.shared.coreDataService
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Quiz Session Management
    
    func saveQuizSession(
        quizType: String,
        score: Int,
        correctAnswers: Int,
        totalWords: Int,
        duration: TimeInterval,
        accuracy: Double,
        wordsPracticed: [CDWord],
        correctWordIds: [String] = []
    ) {
        let session = CDQuizSession(context: coreDataService.context)
        session.id = UUID()
        session.date = Date()
        session.quizType = quizType
        session.totalWords = Int32(totalWords)
        session.correctAnswers = Int32(correctAnswers)
        session.score = Int32(score)
        session.duration = duration
        session.accuracy = accuracy
        
        // Encode words practiced as word IDs
        let wordIds = wordsPracticed.compactMap { $0.id?.uuidString }
        session.wordsPracticed = try? JSONEncoder().encode(wordIds)
        
        // Update word progress for each practiced word
        for word in wordsPracticed {
            let wordId = word.id?.uuidString ?? ""
            let wasCorrect = correctWordIds.contains(wordId)
            updateWordProgress(wordId: wordId, wasCorrect: wasCorrect)
        }
        
        // Update user stats
        updateUserStats(session: session)
        
        do {
            try coreDataService.saveContext()
        } catch {
            print("❌ Failed to save quiz session: \(error)")
        }
    }
    
    // MARK: - Word Progress Management
    
    private func updateWordProgress(wordId: String, wasCorrect: Bool) {
        let request = CDWordProgress.fetchRequest()
        request.predicate = NSPredicate(format: "wordId == %@", wordId)
        
        do {
            let results = try coreDataService.context.fetch(request)
            let progress = results.first ?? CDWordProgress(context: coreDataService.context)
            
            if progress.id == nil {
                progress.id = UUID()
                progress.wordId = wordId
                progress.masteryLevel = "inProgress"
            }
            
            progress.totalAttempts += 1
            progress.lastPracticed = Date()
            
            if wasCorrect {
                progress.correctAttempts += 1
                progress.consecutiveCorrect += 1
            } else {
                progress.consecutiveCorrect = 0
            }
            
            // Update mastery level based on performance
            updateMasteryLevel(for: progress)
            
        } catch {
            print("❌ Failed to update word progress: \(error)")
        }
    }
    
    private func updateMasteryLevel(for progress: CDWordProgress) {
        let totalAttempts = progress.totalAttempts
        let correctAttempts = progress.correctAttempts
        let consecutiveCorrect = progress.consecutiveCorrect
        
        let accuracy = totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0.0
        
        if accuracy >= 0.9 && consecutiveCorrect >= 5 {
            progress.masteryLevel = "mastered"
        } else if accuracy >= 0.7 {
            progress.masteryLevel = "inProgress"
        } else {
            progress.masteryLevel = "needsReview"
        }
        
        // Calculate difficulty score (0-1, higher = more difficult)
        progress.difficultyScore = 1.0 - accuracy
    }
    
    // MARK: - User Stats Management
    
    private func updateUserStats(session: CDQuizSession) {
        let request = CDUserStats.fetchRequest()
        
        do {
            let results = try coreDataService.context.fetch(request)
            let stats = results.first ?? CDUserStats(context: coreDataService.context)
            
            if stats.id == nil {
                stats.id = UUID()
                stats.totalPracticeTime = 0
                stats.totalSessions = 0
                stats.totalWordsStudied = 0
                stats.averageAccuracy = 0
                stats.currentStreak = 0
                stats.longestStreak = 0
                stats.vocabularySize = 0
            }
            
            // Update stats
            stats.totalPracticeTime += session.duration
            stats.totalSessions += 1
            stats.totalWordsStudied += session.totalWords
            stats.lastPracticeDate = Date()
            
            // Update accuracy
            let totalSessions = Double(stats.totalSessions)
            let sessionAccuracy = session.accuracy
            let currentAccuracy = stats.averageAccuracy
            let newAccuracy = (currentAccuracy * (totalSessions - 1) + sessionAccuracy) / totalSessions
            stats.averageAccuracy = newAccuracy
            
            // Update vocabulary size
            updateVocabularySize(stats: stats)
            
        } catch {
            print("❌ Failed to update user stats: \(error)")
        }
    }
    
    private func updateVocabularySize(stats: CDUserStats) {
        let request = CDWord.fetchRequest()
        
        do {
            let wordCount = try coreDataService.context.count(for: request)
            stats.vocabularySize = Int32(wordCount)
        } catch {
            print("❌ Failed to update vocabulary size: \(error)")
        }
    }
    
    // MARK: - Analytics Queries
    
    func getQuizSessions(limit: Int = 50) -> [CDQuizSession] {
        let request = CDQuizSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
            print("❌ Failed to fetch quiz sessions: \(error)")
            return []
        }
    }
    
    func getUserStats() -> CDUserStats? {
        let request = CDUserStats.fetchRequest()
        
        do {
            let results = try coreDataService.context.fetch(request)
            return results.first
        } catch {
            print("❌ Failed to fetch user stats: \(error)")
            return nil
        }
    }
    
    func getWordProgress() -> [CDWordProgress] {
        let request = CDWordProgress.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastPracticed", ascending: false)]
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
            print("❌ Failed to fetch word progress: \(error)")
            return []
        }
    }
    
    func getAllWords() -> [CDWord] {
        let request = CDWord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
            print("❌ Failed to fetch all words: \(error)")
            return []
        }
    }
    
    func getProgressSummary() -> ProgressSummary {
        let wordProgress = getWordProgress()
        let userStats = getUserStats()
        
        let inProgress = wordProgress.filter { $0.masteryLevel == "inProgress" }.count
        let mastered = wordProgress.filter { $0.masteryLevel == "mastered" }.count
        let needsReview = wordProgress.filter { $0.masteryLevel == "needsReview" }.count
        
        return ProgressSummary(
            inProgress: inProgress,
            mastered: mastered,
            needsReview: needsReview,
            totalPracticeTime: userStats?.totalPracticeTime ?? 0,
            totalSessions: Int(userStats?.totalSessions ?? 0),
            averageAccuracy: userStats?.averageAccuracy ?? 0,
            vocabularySize: Int(userStats?.vocabularySize ?? 0)
        )
    }
}

// MARK: - Data Models

struct ProgressSummary {
    let inProgress: Int
    let mastered: Int
    let needsReview: Int
    let totalPracticeTime: TimeInterval
    let totalSessions: Int
    let averageAccuracy: Double
    let vocabularySize: Int
}

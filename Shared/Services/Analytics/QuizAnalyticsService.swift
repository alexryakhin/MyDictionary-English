//
//  QuizAnalyticsService.swift
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
    
    private let coreDataService = CoreDataService.shared
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
        wordsPracticed: [any QuizWord],
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
        let wordIds = wordsPracticed.map { $0.quiz_id }
        session.wordsPracticed = try? JSONEncoder().encode(wordIds)
        
        // Update word progress for each practiced word
        for word in wordsPracticed {
            let wordId = word.quiz_id
            let wasCorrect = correctWordIds.contains(wordId)
            updateWordProgress(wordId: wordId, wasCorrect: wasCorrect)
        }
        
        // Update user stats
        updateUserStats(session: session)
        
        do {
            try coreDataService.saveContext()
        } catch {
            print("❌ Failed to save quiz session: \(CoreError.analyticsError(.quizSessionSaveFailed))")
        }
    }
    
    // MARK: - Word Progress Management
    
    private func updateWordProgress(wordId: String, wasCorrect: Bool) {
        // Try to find the word in Core Data first (private words)
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", wordId)
        
        if let word = try? coreDataService.context.fetch(fetchRequest).first {
            // This is a private word - the difficulty score has already been updated by the QuizWord protocol
            // Just ensure it's marked for sync
            word.updatedAt = Date()
            word.isSynced = false // Mark for sync
        } else {
            // This is a shared word - the difficulty score has already been updated by the QuizWord protocol
            print("📝 [QuizAnalyticsService] Word \(wordId) not found in Core Data - shared word difficulty score already updated")
        }
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
            
            print("🔹 iOS Practice time: currentTotal=\(stats.totalPracticeTime) seconds, newSession=\(session.duration) seconds, newTotal=\(stats.totalPracticeTime) seconds (\(stats.totalPracticeTime/60.0) minutes)")
            
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
    
    func getWordProgress(for wordId: String) -> CDWordProgress? {
        let request = CDWordProgress.fetchRequest()
        request.predicate = NSPredicate(format: "wordId == %@", wordId)
        request.fetchLimit = 1
        
        do {
            return try coreDataService.context.fetch(request).first
        } catch {
            print("❌ Failed to fetch word progress for \(wordId): \(error)")
            return nil
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
        let words = getAllWords()
        let userStats = getUserStats()
        
        // Calculate progress from word difficulty levels
        let inProgress = words.filter { $0.difficultyLevel == .inProgress }.count
        let needsReview = words.filter { $0.difficultyLevel == .needsReview }.count
        let mastered = words.filter { $0.difficultyLevel == .mastered }.count

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

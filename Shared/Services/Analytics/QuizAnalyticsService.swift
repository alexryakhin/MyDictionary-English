//
//  QuizAnalyticsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Foundation
import Combine
import FirebaseAnalytics

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: parameters ?? event.parameters)
        print("🔹 Analytics log event: \(event.rawValue)")
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
        totalItems: Int,
        duration: TimeInterval,
        accuracy: Double,
        itemsPracticed: [any Quizable],
        correctItemIds: [String] = []
    ) {
        let session = CDQuizSession(context: coreDataService.context)
        session.id = UUID()
        session.date = Date()
        session.quizType = quizType
        session.totalWords = Int32(totalItems)
        session.correctAnswers = Int32(correctAnswers)
        session.score = Int32(score)
        session.duration = duration
        session.accuracy = accuracy
        
        // Encode words practiced as word IDs
        let itemIds = itemsPracticed.map { $0.quiz_id }
        session.wordsPracticed = try? JSONEncoder().encode(itemIds)

        // Update word progress for each practiced word
        for item in itemsPracticed {
            let itemId = item.quiz_id
            let wasCorrect = correctItemIds.contains(itemId)
            switch item.quiz_itemType {
            case .word:
                updateWordProgress(wordId: itemId, wasCorrect: wasCorrect)
            case .sharedWord:
                break
            case .idiom:
                updateIdiomProgress(idiomId: itemId, wasCorrect: wasCorrect)
            }
        }
        
        // Update user stats
        updateUserStats(session: session)
        try? coreDataService.saveContext()
    }
    
    // MARK: - Word Progress Management
    
    private func updateWordProgress(wordId: String, wasCorrect: Bool) {
        // Try to find the word in Core Data first (private words)
        let fetchRequest = CDWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", wordId)
        
        if let word = try? coreDataService.context.fetch(fetchRequest).first {
            word.updatedAt = Date()
            word.isSynced = false // Mark for sync
        }
    }
    
    // MARK: - Idiom Progress Management
    
    private func updateIdiomProgress(idiomId: String, wasCorrect: Bool) {
        // Try to find the idiom in Core Data first (private idioms)
        let fetchRequest = CDIdiom.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", idiomId)
        
        if let idiom = try? coreDataService.context.fetch(fetchRequest).first {
            // Update idiom difficulty based on quiz performance using the same scoring system as words
            if wasCorrect {
                idiom.quiz_updateDifficultyScore(5) // Add 5 points for correct answer
            } else {
                idiom.quiz_updateDifficultyScore(-10) // Subtract 10 points for incorrect answer
            }
        }
    }
    
    // MARK: - User Stats Management
    
    private func updateUserStats(session: CDQuizSession) {
        let request = CDUserStats.fetchRequest()
        
        let results = try? coreDataService.context.fetch(request)
        let stats = results?.first ?? CDUserStats(context: coreDataService.context)

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
    }
    
    private func updateVocabularySize(stats: CDUserStats) {
        let wordRequest = CDWord.fetchRequest()
        let idiomRequest = CDIdiom.fetchRequest()
        
        let privateWordCount = (try? coreDataService.context.count(for: wordRequest)) ?? .zero
        let privateIdiomCount = (try? coreDataService.context.count(for: idiomRequest)) ?? .zero

        // Add shared dictionary words count
        let dictionaryService = DictionaryService.shared
        let sharedWordCount = dictionaryService.sharedWords.values.flatMap { $0 }.count

        let totalVocabularySize = privateWordCount + privateIdiomCount + sharedWordCount
        stats.vocabularySize = Int32(totalVocabularySize)
    }
    
    // MARK: - Analytics Queries
    
    func getQuizSessions(limit: Int? = nil) -> [CDQuizSession] {
        let request = CDQuizSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
            return []
        }
    }
    
    func getUserStats() -> CDUserStats? {
        let request = CDUserStats.fetchRequest()
        
        do {
            let results = try coreDataService.context.fetch(request)
            return results.first
        } catch {
            return nil
        }
    }
    
    func getWordProgress() -> [CDWordProgress] {
        let request = CDWordProgress.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastPracticed", ascending: false)]
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
            return []
        }
    }
    
    func getIdiomProgress() -> [CDIdiomProgress] {
        let request = CDIdiomProgress.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastPracticed", ascending: false)]
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
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
            return nil
        }
    }
    
    func getAllItems() -> [any Quizable] {
        let request = CDWord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        var items: [any Quizable] = []

        let coreDataItems = (try? coreDataService.context.fetch(request)) ?? []
        items.append(contentsOf: coreDataItems)

        let sharedWords = DictionaryService.shared.sharedWords.values.flatMap { $0 }
        items.append(contentsOf: sharedWords)

        return items
    }
    
    func generateActivityDataForMonth(
        monthStart: Date,
        sessions: [CDQuizSession]
    ) -> [MonthChartView.ActivityData] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
            return []
        }
        
        var activityData: [MonthChartView.ActivityData] = []
        var currentDate = monthInterval.start
        
        while currentDate < monthInterval.end {
            // Find sessions for this date
            let sessionsOnDate = sessions.filter { session in
                guard let sessionDate = session.date else { return false }
                let sessionComponents = calendar.dateComponents([.year, .month, .day], from: sessionDate)
                let currentComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                return sessionComponents.year == currentComponents.year &&
                       sessionComponents.month == currentComponents.month &&
                       sessionComponents.day == currentComponents.day
            }
            
            let quizCount = sessionsOnDate.count
            
            // Calculate grid coordinates for the month
            let dayOfWeek = calendar.component(.weekday, from: currentDate) - 1 // 0 = Sunday, 1 = Monday, etc.
            let dayOfMonth = calendar.component(.day, from: currentDate)
            
            // Calculate which week of the month this day belongs to
            let firstDayOfMonth = monthInterval.start
            let firstDayOfWeek = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0 = Sunday, 1 = Monday, etc.
            
            // Calculate the week number: (dayOfMonth - 1 + firstDayOfWeek) / 7
            let calculatedWeek = (dayOfMonth - 1 + firstDayOfWeek) / 7
            
            activityData.append(MonthChartView.ActivityData(
                date: currentDate,
                week: calculatedWeek,
                day: dayOfWeek,
                quizCount: quizCount
            ))
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return activityData
    }
    
    func getProgressSummary() -> ProgressSummary {
        let privateItems = getAllItems()
        let userStats = getUserStats()
        
        // Get shared dictionary words
        let dictionaryService = DictionaryService.shared
        let sharedWords = dictionaryService.sharedWords.values.flatMap { $0 }

        // Calculate progress from private word difficulty levels
        let privateInProgress = privateItems.filter { $0.difficultyLevel == .inProgress }.count
        let privateNeedsReview = privateItems.filter { $0.difficultyLevel == .needsReview }.count
        let privateMastered = privateItems.filter { $0.difficultyLevel == .mastered }.count
        
        // Calculate progress from shared word difficulty levels for current user
        let userEmail = AuthenticationService.shared.userEmail
        let sharedInProgress = sharedWords.filter { 
            guard let email = userEmail else { return false }
            return $0.getDifficultyFor(email) == 1 // inProgress
        }.count
        let sharedNeedsReview = sharedWords.filter { 
            guard let email = userEmail else { return false }
            return $0.getDifficultyFor(email) == 2 // needsReview
        }.count
        let sharedMastered = sharedWords.filter { 
            guard let email = userEmail else { return false }
            return $0.getDifficultyFor(email) == 3 // mastered
        }.count
        
        // Combine private and shared word counts
        let totalInProgress = privateInProgress + sharedInProgress
        let totalNeedsReview = privateNeedsReview + sharedNeedsReview
        let totalMastered = privateMastered + sharedMastered
        
        // Calculate total vocabulary size including shared words
        let totalVocabularySize = privateItems.count + sharedWords.count

        return ProgressSummary(
            inProgress: totalInProgress,
            mastered: totalMastered,
            needsReview: totalNeedsReview,
            totalPracticeTime: userStats?.totalPracticeTime ?? 0,
            totalSessions: Int(userStats?.totalSessions ?? 0),
            averageAccuracy: userStats?.averageAccuracy ?? 0,
            vocabularySize: totalVocabularySize
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

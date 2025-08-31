//
//  QuizUsageTracker.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//
//  Usage Example:
//  let quizTracker = QuizUsageTracker.shared
//  
//  // Check if user can run a quiz today
//  if quizTracker.canRunQuizToday(.contextMultipleChoice) {
//      // Allow user to start the quiz
//      quizTracker.recordQuizOpened(.contextMultipleChoice)
//  } else {
//      // Show "already used today" message
//  }
//

import Foundation

final class QuizUsageTracker {
    
    static let shared = QuizUsageTracker()
    
    private let authenticationService = AuthenticationService.shared
    private let subscriptionService = SubscriptionService.shared
    
    private init() {}
    
    /// Checks if the user can run a specific AI quiz today
    /// - Parameter quizType: The type of quiz to check
    /// - Returns: true if user can run the quiz today, false otherwise
    func canRunQuizToday(_ quizType: Quiz) throws -> Bool {
        // Only authenticated users can run AI quizzes
        guard authenticationService.isSignedIn else {
            throw DictionaryError.userNotAuthenticated
        }

        // Pro users have unlimited access
        if subscriptionService.isProUser {
            return true
        }
        
        // Check if it's a new day since last usage
        let today = Calendar.current.startOfDay(for: Date())
        let lastUsageDate = getLastUsageDate(for: quizType)
        let lastUsageDay = Calendar.current.startOfDay(for: lastUsageDate)
        
        // If it's a new day, user can run the quiz
        return !Calendar.current.isDate(today, inSameDayAs: lastUsageDay)
    }
    
    /// Records that a user has opened/started a specific AI quiz today
    /// - Parameter quizType: The type of quiz that was opened
    func recordQuizOpened(_ quizType: Quiz) {
        // Pro users don't need tracking
        if subscriptionService.isProUser {
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        setLastUsageDate(today, for: quizType)
        
        print("📊 [QuizUsageTracker] Recorded \(quizType.title) quiz opened on \(today)")
    }
    
    /// Gets the last date when a specific quiz was used
    /// - Parameter quizType: The type of quiz to check
    /// - Returns: The last usage date, or distant past if never used
    func getLastUsageDate(for quizType: Quiz) -> Date {
        switch quizType {
        case .contextMultipleChoice:
            return UDService.contextMultipleChoiceQuizUsageDate ?? Date.distantPast
        case .fillInTheBlank:
            return UDService.fillInTheBlankQuizUsageDate ?? Date.distantPast
        case .sentenceWriting:
            return UDService.sentenceWritingQuizUsageDate ?? Date.distantPast
        case .spelling, .chooseDefinition:
            // These don't use AI, so they don't need tracking
            return Date.distantPast
        }
    }
    
    /// Sets the last usage date for a specific quiz
    /// - Parameters:
    ///   - date: The date to set
    ///   - quizType: The type of quiz
    private func setLastUsageDate(_ date: Date, for quizType: Quiz) {
        switch quizType {
        case .contextMultipleChoice:
            UDService.contextMultipleChoiceQuizUsageDate = date
        case .fillInTheBlank:
            UDService.fillInTheBlankQuizUsageDate = date
        case .sentenceWriting:
            UDService.sentenceWritingQuizUsageDate = date
        case .spelling, .chooseDefinition:
            // These don't use AI, so they don't need tracking
            break
        }
    }
    
    /// Checks if a specific quiz type uses AI
    /// - Parameter quizType: The quiz type to check
    /// - Returns: true if the quiz uses AI, false otherwise
    func isAIQuiz(_ quizType: Quiz) -> Bool {
        switch quizType {
        case .contextMultipleChoice, .fillInTheBlank, .sentenceWriting:
            return true
        case .spelling, .chooseDefinition:
            return false
        }
    }
    
    /// Gets all AI quiz types
    /// - Returns: Array of AI-powered quiz types
    func getAIQuizzes() -> [Quiz] {
        return [.contextMultipleChoice, .fillInTheBlank, .sentenceWriting]
    }
}

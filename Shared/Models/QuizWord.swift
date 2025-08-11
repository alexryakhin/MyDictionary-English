//
//  QuizWord.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

// MARK: - Quiz Word Protocol

/// Protocol that defines the interface for words that can be used in quizzes
/// This allows both private (CDWord) and shared (SharedWord) words to be used interchangeably
protocol QuizWord: Identifiable {
    var quiz_id: String { get }
    var quiz_wordItself: String { get }
    var quiz_definition: String { get }
    var quiz_partOfSpeech: String { get }
    var quiz_difficultyScore: Int { get }
    var quiz_languageCode: String { get }

    var difficultyLevel: Difficulty { get }

    /// Updates the difficulty score of the word based on quiz performance
    /// - Parameter points: Points to add (positive for correct, negative for incorrect)
    func quiz_updateDifficultyScore(_ points: Int)
    
    /// Gets the current user's difficulty score for this word
    /// - Parameter userEmail: The user's email
    /// - Returns: The difficulty score for this user
    func quiz_getDifficultyScoreForUser(_ userEmail: String) -> Int
    
    /// Updates the difficulty score for a specific user
    /// - Parameters:
    ///   - points: Points to add (positive for correct, negative for incorrect)
    ///   - userEmail: The user's email
    func quiz_updateDifficultyScoreForUser(_ points: Int, userEmail: String)
}

// MARK: - CDWord Extension

extension CDWord: QuizWord {
    var quiz_id: String {
        return self.id?.uuidString ?? ""
    }
    
    var quiz_wordItself: String {
        return self.wordItself ?? ""
    }
    
    var quiz_definition: String {
        return self.definition ?? ""
    }
    
    var quiz_partOfSpeech: String {
        return self.partOfSpeech ?? ""
    }
    
    var quiz_difficultyScore: Int {
        return Int(self.difficultyScore)
    }
    
    var quiz_languageCode: String {
        return self.languageCode ?? "en"
    }

    func quiz_updateDifficultyScore(_ points: Int) {
        let currentScore = Int(self.difficultyScore)
        let newScore = calculateNewScore(currentScore: currentScore, pointsToAdd: points)
        self.difficultyScore = Int32(newScore)
        self.isSynced = false  // Mark as unsynced to trigger Firebase sync
        self.updatedAt = Date()
        do {
            try CoreDataService.shared.saveContext()
        } catch {
            print("❌ Failed to update word difficulty score: \(error)")
        }
    }
    
    func quiz_getDifficultyScoreForUser(_ userEmail: String) -> Int {
        // For private words, return the global difficulty score
        return self.quiz_difficultyScore
    }
    
    func quiz_updateDifficultyScoreForUser(_ points: Int, userEmail: String) {
        // For private words, update the global difficulty score
        quiz_updateDifficultyScore(points)
    }
    
    private func calculateNewScore(currentScore: Int, pointsToAdd: Int) -> Int {
        let newScore = currentScore + pointsToAdd
        
        // Apply limits
        if newScore < -20 {
            return -20 // Minimum limit
        }
        
        // Special rule for mastered words (score >= 50) getting incorrect answer
        if currentScore >= 50 && pointsToAdd < 0 {
            return 25 // Reset to 25 for mastered words
        }
        
        return newScore
    }
}

// MARK: - SharedWord Extension

extension SharedWord: QuizWord {
    var quiz_id: String {
        return self.id
    }
    
    var quiz_wordItself: String {
        return self.wordItself
    }
    
    var quiz_definition: String {
        return self.definition
    }
    
    var quiz_partOfSpeech: String {
        return self.partOfSpeech
    }
    
    var quiz_difficultyScore: Int {
        // For shared words, return the current user's difficulty score
        if let userEmail = AuthenticationService.shared.userEmail {
            return self.getDifficultyFor(userEmail)
        }
        return 0
    }
    
    var quiz_languageCode: String {
        return self.languageCode
    }
    
    var difficultyLevel: Difficulty {
        if let userEmail = AuthenticationService.shared.userEmail {
            return Difficulty(score: self.getDifficultyFor(userEmail))
        }
        return .new // Default for shared words without a user
    }

    func quiz_updateDifficultyScore(_ points: Int) {
        // For shared words, update the difficulty for the current user
        if let userEmail = AuthenticationService.shared.userEmail {
            quiz_updateDifficultyScoreForUser(points, userEmail: userEmail)
        }
    }
    
    func quiz_getDifficultyScoreForUser(_ userEmail: String) -> Int {
        return self.getDifficultyFor(userEmail)
    }
    
    func quiz_updateDifficultyScoreForUser(_ points: Int, userEmail: String) {
        // This method should be called through DictionaryService to update Firestore
        // The actual implementation will be handled by DictionaryService
        Task {
            do {
                // Find which dictionary this word belongs to
                let dictionaryService = DictionaryService.shared
                for (dictionaryId, words) in dictionaryService.sharedWords {
                    if words.contains(where: { $0.id == self.id }) {
                        let currentScore = self.getDifficultyFor(userEmail)
                        let newScore = calculateNewScore(currentScore: currentScore, pointsToAdd: points)
                        try await dictionaryService.updateDifficulty(for: self.id, in: dictionaryId, difficulty: newScore)
                        break
                    }
                }
            } catch {
                print("❌ Failed to update shared word difficulty score: \(error)")
            }
        }
    }
    
    private func calculateNewScore(currentScore: Int, pointsToAdd: Int) -> Int {
        let newScore = currentScore + pointsToAdd
        
        // Apply limits
        if newScore < -20 {
            return -20 // Minimum limit
        }
        
        // Special rule for mastered words (score >= 50) getting incorrect answer
        if currentScore >= 50 && pointsToAdd < 0 {
            return 25 // Reset to 25 for mastered words
        }
        
        return newScore
    }
}


//
//  Quizable.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

enum QuizItemType {
    case word
    case sharedWord
    case idiom
}

// MARK: - Quiz Item Protocol

/// Protocol that defines the interface for items that can be used in quizzes
/// This allows both words (CDWord, SharedWord) and idioms (CDIdiom) to be used interchangeably
protocol Quizable: Identifiable {

    var quiz_id: String { get }
    var quiz_text: String { get } // The main text (word or idiom)
    var quiz_definition: String { get }
    var quiz_partOfSpeech: String? { get } // Optional part of speech (nil for idioms)
    var quiz_difficultyScore: Int { get }
    var quiz_languageCode: String { get }
    var quiz_timestamp: Date { get }
    var quiz_itemType: QuizItemType { get }
    var difficultyLevel: Difficulty { get }
    var quiz_imageUrl: String? { get } // Optional image URL from Pexels
    var quiz_imageLocalPath: String? { get } // Optional local image path

    /// Updates the difficulty score of the item based on quiz performance
    /// - Parameter points: Points to add (positive for correct, negative for incorrect)
    func quiz_updateDifficultyScore(_ points: Int)
    
    /// Gets the current user's difficulty score for this item
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

extension CDWord: Quizable {
    var quiz_id: String {
        return self.id?.uuidString ?? ""
    }
    
    var quiz_text: String {
        return self.wordItself ?? ""
    }
    
    var quiz_definition: String {
        // Randomly select from available meanings to provide variety in quizzes
        let availableMeanings = self.meaningsArray
        if !availableMeanings.isEmpty {
            // Randomly select a meaning for quiz variety
            let randomMeaning = availableMeanings.randomElement()!
            return randomMeaning.definition ?? ""
        }
        // Fallback to primary meaning if no meanings available
        return self.primaryDefinition ?? self.definition ?? ""
    }
    
    var quiz_partOfSpeech: String? {
        return self.partOfSpeech
    }
    
    var quiz_difficultyScore: Int {
        return Int(self.difficultyScore)
    }
    
    var quiz_languageCode: String {
        return self.languageCode ?? "en"
    }

    var quiz_timestamp: Date {
        return self.timestamp ?? .now
    }

    var quiz_itemType: QuizItemType {
        // Check if this is an expression (idiom/phrase) based on partOfSpeech
        if self.isExpression {
            return .idiom // Keep .idiom for backward compatibility with existing quiz logic
        }
        return .word
    }
    
    var quiz_imageUrl: String? {
        return self.imageUrl
    }
    
    var quiz_imageLocalPath: String? {
        return self.imageLocalPath
    }

    func quiz_updateDifficultyScore(_ points: Int) {
        let currentScore = Int(self.difficultyScore)
        let newScore = calculateNewScore(currentScore: currentScore, pointsToAdd: points)
        self.difficultyScore = Int32(newScore)
        self.isSynced = false  // Mark as unsynced to trigger Firebase sync
        self.updatedAt = Date()
        try? CoreDataService.shared.saveContext()
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

// MARK: - CDIdiom Extension

extension CDIdiom: Quizable {
    var quiz_id: String {
        return self.id?.uuidString ?? ""
    }
    
    var quiz_text: String {
        return self.idiomItself ?? ""
    }
    
    var quiz_definition: String {
        return self.definition ?? ""
    }
    
    var quiz_partOfSpeech: String? {
        return nil // Idioms don't have parts of speech
    }
    
    var quiz_difficultyScore: Int {
        return Int(self.difficultyScore)
    }

    var quiz_languageCode: String {
        return self.languageCode ?? "en"
    }

    var quiz_timestamp: Date {
        return self.timestamp ?? .now
    }

    var quiz_itemType: QuizItemType {
        .idiom
    }
    
    var quiz_imageUrl: String? {
        return nil // Idioms don't have images yet
    }
    
    var quiz_imageLocalPath: String? {
        return nil // Idioms don't have images yet
    }

    func quiz_updateDifficultyScore(_ points: Int) {
        let currentScore = Int(self.difficultyScore)
        let newScore = calculateNewScore(currentScore: currentScore, pointsToAdd: points)
        self.difficultyScore = Int32(newScore)
        try? CoreDataService.shared.saveContext()
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

extension SharedWord: Quizable {
    var quiz_id: String {
        return self.id
    }
    
    var quiz_text: String {
        return self.wordItself
    }
    
    var quiz_definition: String {
        return self.definition
    }
    
    var quiz_partOfSpeech: String? {
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

    var quiz_timestamp: Date {
        return self.timestamp
    }

    var quiz_itemType: QuizItemType {
        .sharedWord
    }
    
    var quiz_imageUrl: String? {
        return self.imageUrl
    }
    
    var quiz_imageLocalPath: String? {
        return self.imageLocalPath
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
        Task { @MainActor in
            do {
                // Find which dictionary this word belongs to
                let dictionaryService = DictionaryService.shared
                for (dictionaryId, words) in dictionaryService.sharedWords {
                    if words.contains(where: { $0.id == self.id }) {
                        let currentScore = self.getDifficultyFor(userEmail)
                        let newScore = calculateNewScore(currentScore: currentScore, pointsToAdd: points)
                        try await dictionaryService.updateDifficulty(for: self.id, in: dictionaryId, difficulty: newScore)

                        // Update local cache immediately for better UX
                        if let wordIndex = dictionaryService.sharedWords[dictionaryId]?.firstIndex(where: { $0.id == self.id }) {
                            var updatedWords = dictionaryService.sharedWords[dictionaryId] ?? []
                            var updatedWord = updatedWords[wordIndex]
                            updatedWord.difficulties[userEmail] = newScore
                            updatedWords[wordIndex] = updatedWord
                            dictionaryService.sharedWords[dictionaryId] = updatedWords
                        }
                        break
                    }
                }
            } catch {
                AlertCenter.shared.showAlert(with: .info(title: error.localizedDescription))
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


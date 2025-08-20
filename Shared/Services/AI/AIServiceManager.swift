//
//  AIServiceManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine

// MARK: - AI Service Interface

protocol AIServiceInterface {
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int,
        targetLanguage: String?,
        userId: String
    ) async throws -> AIWordResponse
}

// MARK: - AI Service Manager Interface

protocol AIServiceManagerInterface {
    func enhanceWordDefinition(
        word: String,
        originalDefinition: String,
        context: String?,
        userLevel: String?
    ) async throws -> String

    func generateAdditionalExamples(
        for word: String,
        definition: String,
        existingExamples: [String],
        count: Int,
        context: String?
    ) async throws -> [String]

    func generateQuizQuestion(
        word: String,
        definition: String,
        difficulty: Difficulty,
        questionType: QuizQuestionType
    ) async throws -> AIQuizQuestion

    func generatePersonalizedExplanation(
        word: String,
        definition: String,
        userProfile: AIUserProfile?
    ) async throws -> String

    func analyzeLearningProgress(
        items: [any Quizable],
        quizResults: [CDQuizSession]
    ) async throws -> AILearningInsights
}

// MARK: - AI Models

struct AIQuizQuestion {
    let question: String
    let correctAnswer: String
    let distractors: [String]
    let explanation: String?
    let difficulty: Difficulty
    let questionType: QuizQuestionType
}

struct AIUserProfile {
    let learningLevel: String
    let interests: [String]
    let learningStyle: String
    let preferredContext: String?
}

struct AILearningInsights {
    let weakAreas: [String]
    let recommendedWords: [String]
    let studySuggestions: [String]
    let progressTrend: String
    let estimatedMasteryTime: String
}

enum QuizQuestionType: String, CaseIterable {
    case definition = "definition"
    case example = "example"
    case context = "context"
    case synonym = "synonym"
    case antonym = "antonym"

    var displayName: String {
        switch self {
        case .definition:
            return Loc.Quiz.questionTypeDefinition.localized
        case .example:
            return Loc.Quiz.questionTypeExample.localized
        case .context:
            return Loc.Quiz.questionTypeContext.localized
        case .synonym:
            return Loc.Quiz.questionTypeSynonym.localized
        case .antonym:
            return Loc.Quiz.questionTypeAntonym.localized
        }
    }
}

// MARK: - AI Service Manager

final class AIServiceManager: AIServiceManagerInterface {

    static let shared = AIServiceManager()

    private let openAIService: AIServiceInterface

    private init() {
        #if DEBUG
        self.openAIService = OpenAIAPIService()
        print("🔧 [AIServiceManager] Using OpenAIAPIService for DEBUG mode")
        #else
        self.openAIService = FirebaseOpenAIProxy.shared
        print("🔧 [AIServiceManager] Using FirebaseOpenAIProxy for RELEASE mode")
        #endif
    }

    // MARK: - Enhanced Definition Generation

    func enhanceWordDefinition(
        word: String,
        originalDefinition: String,
        context: String? = nil,
        userLevel: String? = nil
    ) async throws -> String {
        print("🔍 [AIServiceManager] enhanceWordDefinition called for word: '\(word)'")
        print("🔍 [AIServiceManager] Original definition: \(originalDefinition)")
        print("🔍 [AIServiceManager] Context: \(context ?? "nil"), UserLevel: \(userLevel ?? "nil")")
        
        do {
            print("🚀 [AIServiceManager] Calling Firebase proxy for enhanced definition...")
            let wordInfo = try await openAIService.generateWordInformation(
                for: word,
                maxDefinitions: 1,
                targetLanguage: nil,
                userId: "test-user-123" // TODO: Replace with actual user ID
            )

            print("✅ [AIServiceManager] Successfully enhanced definition for '\(word)'")
            let enhancedDefinition = wordInfo.definitions.first?.definition ?? originalDefinition
            print("🔍 [AIServiceManager] Enhanced definition: \(enhancedDefinition)")

            return enhancedDefinition
        } catch {
            print("❌ [AIServiceManager] AI definition generation failed for '\(word)': \(error.localizedDescription)")
            // Fallback to original definition if AI fails
            print("AI definition generation failed for '\(word)': \(error.localizedDescription)")
            print("🔄 [AIServiceManager] Falling back to original definition")
            return originalDefinition
        }
    }

    // MARK: - Example Generation

    func generateAdditionalExamples(
        for word: String,
        definition: String,
        existingExamples: [String],
        count: Int = 3,
        context: String? = nil
    ) async throws -> [String] {
        print("🔍 [AIServiceManager] generateAdditionalExamples called for word: '\(word)'")
        print("🔍 [AIServiceManager] Existing examples count: \(existingExamples.count)")
        print("🔍 [AIServiceManager] Requested count: \(count), Context: \(context ?? "nil")")
        
        do {
            print("🚀 [AIServiceManager] Calling Firebase proxy for examples...")
            let wordInfo = try await openAIService.generateWordInformation(
                for: word,
                maxDefinitions: 1,
                targetLanguage: nil,
                userId: "test-user-123" // TODO: Replace with actual user ID
            )

            print("✅ [AIServiceManager] Received examples from Firebase proxy")
            let newExamples = wordInfo.definitions.first?.examples ?? []
            print("🔍 [AIServiceManager] New examples: \(newExamples)")

            // Filter out examples that are too similar to existing ones
            print("🔍 [AIServiceManager] Filtering examples for similarity...")
            let filteredExamples = newExamples.filter { newExample in
                !existingExamples.contains { existing in
                    similarityScore(between: newExample, and: existing) > 0.7
                }
            }

            print("✅ [AIServiceManager] Filtered to \(filteredExamples.count) unique examples")
            let result = Array(filteredExamples.prefix(count))
            print("🔍 [AIServiceManager] Returning \(result.count) examples")
            return result
        } catch {
            print("❌ [AIServiceManager] AI example generation failed for '\(word)': \(error.localizedDescription)")
            print("AI example generation failed for '\(word)': \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Quiz Question Generation

    func generateQuizQuestion(
        word: String,
        definition: String,
        difficulty: Difficulty,
        questionType: QuizQuestionType
    ) async throws -> AIQuizQuestion {
        // TODO: Implement quiz question generation through Firebase proxy
        // For now, return a placeholder
        print("🔍 [AIServiceManager] generateQuizQuestion called for word: '\(word)'")
        print("⚠️ [AIServiceManager] Quiz question generation not yet implemented in Firebase proxy")
        
        // Return a simple placeholder quiz question
        return AIQuizQuestion(
            question: "What does '\(word)' mean?",
            correctAnswer: definition,
            distractors: ["A type of food", "A color", "A place"],
            explanation: nil,
            difficulty: difficulty,
            questionType: questionType
        )
    }

    // MARK: - Personalized Explanation

    func generatePersonalizedExplanation(
        word: String,
        definition: String,
        userProfile: AIUserProfile? = nil
    ) async throws -> String {
        print("🔍 [AIServiceManager] generatePersonalizedExplanation called for word: '\(word)'")
        
        do {
            print("🚀 [AIServiceManager] Calling Firebase proxy for personalized explanation...")
            let wordInfo = try await openAIService.generateWordInformation(
                for: word,
                maxDefinitions: 1,
                targetLanguage: nil,
                userId: "test-user-123" // TODO: Replace with actual user ID
            )

            let explanation = wordInfo.definitions.first?.definition ?? definition
            print("✅ [AIServiceManager] Successfully generated personalized explanation")
            return explanation
        } catch {
            print("❌ [AIServiceManager] AI personalized explanation failed for '\(word)': \(error.localizedDescription)")
            return definition
        }
    }

    // MARK: - Learning Progress Analysis

        func analyzeLearningProgress(
        items: [any Quizable],
        quizResults: [CDQuizSession]
    ) async throws -> AILearningInsights {
        // This is a placeholder for future implementation
        // For now, we'll provide basic insights based on analytics data
        
        let weakAreas = identifyWeakAreas(from: items, quizResults: quizResults)
        let recommendedWords = recommendWords(from: items, weakAreas: weakAreas)
        let studySuggestions = generateStudySuggestions(weakAreas: weakAreas)
        let progressTrend = analyzeProgressTrend(quizResults: quizResults)
        let estimatedMasteryTime = estimateMasteryTime(items: items, quizResults: quizResults)

        return AILearningInsights(
            weakAreas: weakAreas,
            recommendedWords: recommendedWords,
            studySuggestions: studySuggestions,
            progressTrend: progressTrend,
            estimatedMasteryTime: estimatedMasteryTime
        )
    }
    
    // MARK: - Comprehensive Word Information
    
    func generateWordInformation(
        for word: String,
        maxDefinitions: Int = 5,
        targetLanguage: String? = nil
    ) async throws -> AIWordResponse {
        print("🔍 [AIServiceManager] generateWordInformation called for word: '\(word)'")
        print("🔍 [AIServiceManager] Max definitions: \(maxDefinitions)")
        print("🔍 [AIServiceManager] Target language: \(targetLanguage ?? "auto-detect")")
        
        do {
                            print("🚀 [AIServiceManager] Calling OpenAI service for word information...")
                let wordInfo = try await openAIService.generateWordInformation(
                    for: word,
                    maxDefinitions: maxDefinitions,
                    targetLanguage: targetLanguage,
                    userId: "test-user-123" // TODO: Replace with actual user ID
                )
            
            print("✅ [AIServiceManager] Successfully generated word information for '\(word)'")
            print("🔍 [AIServiceManager] Found \(wordInfo.definitions.count) definitions")
            print("🔍 [AIServiceManager] Pronunciation: \(wordInfo.pronunciation)")
            
            return wordInfo
        } catch {
            print("❌ [AIServiceManager] Word information generation failed for '\(word)': \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Helper Methods

    private func similarityScore(between text1: String, and text2: String) -> Double {
        // Simple similarity calculation - can be enhanced with more sophisticated algorithms
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))

        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count

        return union > 0 ? Double(intersection) / Double(union) : 0.0
    }

    private func identifyWeakAreas(from items: [any Quizable], quizResults: [CDQuizSession]) -> [String] {
        // Analyze quiz results to identify areas where user struggles
        var weakAreas: [String] = []

        // Check for words with low difficulty scores
        let difficultWords = items.filter { $0.difficultyLevel == .needsReview }
        if !difficultWords.isEmpty {
            weakAreas.append(Loc.AI.weakAreaDifficultWords.localized)
        }

        // Check for recent quiz performance
        let recentQuizzes = quizResults.suffix(10)
        let averageAccuracy = recentQuizzes.map { $0.accuracy }.reduce(0, +) / Double(recentQuizzes.count)

        if averageAccuracy < 0.7 {
            weakAreas.append(Loc.AI.weakAreaLowAccuracy.localized)
        }

        return weakAreas
    }

    private func recommendWords(from items: [any Quizable], weakAreas: [String]) -> [String] {
        // Recommend items based on weak areas
        var recommendations: [String] = []

        if weakAreas.contains(Loc.AI.weakAreaDifficultWords.localized) {
            let difficultWords = items.filter { $0.difficultyLevel == .needsReview }
            recommendations.append(contentsOf: difficultWords.prefix(5).map { $0.quiz_text })
        }

        return recommendations
    }

    private func generateStudySuggestions(weakAreas: [String]) -> [String] {
        var suggestions: [String] = []

        if weakAreas.contains(Loc.AI.weakAreaDifficultWords.localized) {
            suggestions.append(Loc.AI.suggestionFocusDifficultWords.localized)
        }

        if weakAreas.contains(Loc.AI.weakAreaLowAccuracy.localized) {
            suggestions.append(Loc.AI.suggestionPracticeMore.localized)
        }

        return suggestions
    }

    private func analyzeProgressTrend(quizResults: [CDQuizSession]) -> String {
        guard quizResults.count >= 5 else {
            return Loc.AI.progressTrendInsufficientData.localized
        }

        let recentQuizzes = Array(quizResults.suffix(5))
        let firstAccuracy = recentQuizzes.first?.accuracy ?? 0
        let lastAccuracy = recentQuizzes.last?.accuracy ?? 0

        if lastAccuracy > firstAccuracy + 0.1 {
            return Loc.AI.progressTrendImproving.localized
        } else if lastAccuracy < firstAccuracy - 0.1 {
            return Loc.AI.progressTrendDeclining.localized
        } else {
            return Loc.AI.progressTrendStable.localized
        }
    }

    private func estimateMasteryTime(items: [any Quizable], quizResults: [CDQuizSession]) -> String {
        let totalWords = items.count
        let masteredWords = items.filter { $0.difficultyLevel == .mastered }.count
        let remainingWords = totalWords - masteredWords

        // Rough estimation: 5 minutes per word
        let estimatedMinutes = remainingWords * 5
        let estimatedHours = estimatedMinutes / 60
        let estimatedDays = estimatedHours / 2 // Assuming 2 hours of study per day

        if estimatedDays < 1 {
            return Loc.AI.masteryTimeLessThanDay.localized
        } else if estimatedDays < 7 {
            return Loc.AI.masteryTimeLessThanWeek.localized(estimatedDays)
        } else {
            let weeks = estimatedDays / 7
            return Loc.AI.masteryTimeWeeks.localized(weeks)
        }
    }
}

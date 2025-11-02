//
//  AIStoryResponse.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation
import OpenAI

// MARK: - Story Input

struct StoryInput: Codable {
    let savedWords: [String]?
    let customText: String?
    let targetLanguage: InputLanguage
    let cefrLevel: CEFRLevel
    let pageCount: Int
    
    init(
        savedWords: [String]? = nil,
        customText: String? = nil,
        targetLanguage: InputLanguage,
        cefrLevel: CEFRLevel,
        pageCount: Int
    ) {
        self.savedWords = savedWords
        self.customText = customText
        self.targetLanguage = targetLanguage
        self.cefrLevel = cefrLevel
        self.pageCount = pageCount
    }
}

// MARK: - Story Lab Config

struct StoryLabConfig: Hashable, Codable {
    let savedWords: [String]?
    let customText: String?
    let targetLanguage: InputLanguage
    let cefrLevel: CEFRLevel
    let pageCount: Int
    
    init(
        savedWords: [String]? = nil,
        customText: String? = nil,
        targetLanguage: InputLanguage,
        cefrLevel: CEFRLevel,
        pageCount: Int
    ) {
        self.savedWords = savedWords
        self.customText = customText
        self.targetLanguage = targetLanguage
        self.cefrLevel = cefrLevel
        self.pageCount = pageCount
    }
    
    func toStoryInput() -> StoryInput {
        return StoryInput(
            savedWords: savedWords,
            customText: customText,
            targetLanguage: targetLanguage,
            cefrLevel: cefrLevel,
            pageCount: pageCount
        )
    }
}

// MARK: - Story Response Models

struct AIStoryResponse: Codable, JSONSchemaConvertible {
    let title: String
    let pages: [AIStoryPage]
    let metadata: StoryMetadata
    
    static let example: Self = {
        .init(
            title: "The Library Adventure",
            pages: [AIStoryPage.example],
            metadata: StoryMetadata.example
        )
    }()
}

struct AIStoryPage: Codable, JSONSchemaConvertible {
    let pageNumber: Int
    let storyText: String
    let questions: [AIComprehensionQuestion]
    
    static let example: Self = {
        .init(
            pageNumber: 1,
            storyText: "It was a beautiful day in the park. The sky was blue, and the flowers were vibrant. Suddenly, a little girl picked up an apple from the ground. She exclaimed, \"Look at this shiny apple!\" Everyone turned to see it, curious about its color.",
            questions: [AIComprehensionQuestion.example]
        )
    }()
}

struct AIComprehensionQuestion: Codable, JSONSchemaConvertible {
    let question: String
    let options: [AIComprehensionOption]
    let explanation: String?
    
    static let example: Self = {
        .init(
            question: "What color was the sky in the story?",
            options: [
                AIComprehensionOption(text: "Blue", isCorrect: true),
                AIComprehensionOption(text: "Gray", isCorrect: false),
                AIComprehensionOption(text: "White", isCorrect: false),
                AIComprehensionOption(text: "Green", isCorrect: false)
            ],
            explanation: "The story explicitly states 'The sky was blue' in the first sentence."
        )
    }()
}

struct AIComprehensionOption: Codable, JSONSchemaConvertible {
    let text: String
    let isCorrect: Bool
    
    static let example: Self = {
        .init(
            text: "Blue",
            isCorrect: true
        )
    }()
}

struct StoryMetadata: Codable, JSONSchemaConvertible {
    let cefrLevel: String
    let targetLanguage: String
    let wordCount: Int
    let vocabularyWords: [String]
    
    static let example: Self = {
        .init(
            cefrLevel: "B1",
            targetLanguage: "English",
            wordCount: 50,
            vocabularyWords: ["apple", "exclaimed", "curious"]
        )
    }()
}

// MARK: - Story Session

struct StorySession: Identifiable {
    let id: UUID
    let story: AIStoryResponse
    var currentPageIndex: Int
    var answers: [QuestionKey: Int] // (pageIndex, questionIndex) -> selectedAnswerIndex
    var correctAnswers: Int
    let totalQuestions: Int
    var isComplete: Bool
    var discoveredWords: Set<String>
    
    struct QuestionKey: Hashable, Codable {
        let pageIndex: Int
        let questionIndex: Int
    }
    
    init(story: AIStoryResponse) {
        self.id = UUID()
        self.story = story
        self.currentPageIndex = 0
        self.answers = [:]
        self.correctAnswers = 0
        self.totalQuestions = story.pages.reduce(0) { $0 + $1.questions.count }
        self.isComplete = false
        self.discoveredWords = Set<String>()
    }
    
    init(id: UUID, story: AIStoryResponse, currentPageIndex: Int = 0, answers: [QuestionKey: Int] = [:], correctAnswers: Int = 0, isComplete: Bool = false, discoveredWords: Set<String> = []) {
        self.id = id
        self.story = story
        self.currentPageIndex = currentPageIndex
        self.answers = answers
        self.correctAnswers = correctAnswers
        self.totalQuestions = story.pages.reduce(0) { $0 + $1.questions.count }
        self.isComplete = isComplete
        self.discoveredWords = discoveredWords
    }
    
    var score: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions)) * 100)
    }
    
    mutating func submitAnswer(forPageIndex pageIndex: Int, questionIndex: Int, answerIndex: Int) {
        let key = QuestionKey(pageIndex: pageIndex, questionIndex: questionIndex)
        answers[key] = answerIndex
        
        guard pageIndex < story.pages.count,
              questionIndex < story.pages[pageIndex].questions.count else { return }
        
        let question = story.pages[pageIndex].questions[questionIndex]
        // Check if the selected answer is correct using isCorrect flag
        if answerIndex < question.options.count && question.options[answerIndex].isCorrect {
            correctAnswers += 1
        }
        
        // Check if all questions are answered
        var totalAnswered = 0
        for (pageIdx, page) in story.pages.enumerated() {
            for questionIdx in 0..<page.questions.count {
                let questionKey = QuestionKey(pageIndex: pageIdx, questionIndex: questionIdx)
                if answers[questionKey] != nil {
                    totalAnswered += 1
                }
            }
        }
        isComplete = totalAnswered == totalQuestions
    }
    
    mutating func addDiscoveredWord(_ word: String) {
        discoveredWords.insert(word.lowercased())
    }
}


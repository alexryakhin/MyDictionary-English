//
//  StoryLabSession+CoreDataClass.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation
import CoreData

@objc(CDStoryLabSession)
public class CDStoryLabSession: NSManagedObject {
    
    // MARK: - Computed Properties
    
    var story: AIStoryResponse? {
        get {
            guard let storyData = storyData else { return nil }
            return try? JSONDecoder().decode(AIStoryResponse.self, from: storyData)
        }
        set {
            storyData = try? JSONEncoder().encode(newValue)
            title = newValue?.title
        }
    }
    
    var answers: [StorySession.QuestionKey: Int] {
        get {
            guard let answersData = answersData else { return [:] }
            struct AnswerEntry: Codable {
                let pageIndex: Int
                let questionIndex: Int
                let answerIndex: Int
            }
            guard let decoded = try? JSONDecoder().decode([AnswerEntry].self, from: answersData) else {
                return [:]
            }
            return decoded.reduce(into: [:]) { result, entry in
                let key = StorySession.QuestionKey(pageIndex: entry.pageIndex, questionIndex: entry.questionIndex)
                result[key] = entry.answerIndex
            }
        }
        set {
            struct AnswerEntry: Codable {
                let pageIndex: Int
                let questionIndex: Int
                let answerIndex: Int
            }
            let entries = newValue.map { key, value in
                AnswerEntry(pageIndex: key.pageIndex, questionIndex: key.questionIndex, answerIndex: value)
            }
            answersData = try? JSONEncoder().encode(entries)
        }
    }
    
    var config: StoryLabConfig? {
        get {
            guard let configData = configData else { return nil }
            return try? JSONDecoder().decode(StoryLabConfig.self, from: configData)
        }
        set {
            configData = try? JSONEncoder().encode(newValue)
            if let config = newValue {
                targetLanguage = config.targetLanguage.rawValue
                cefrLevel = config.cefrLevel.rawValue
            }
        }
    }
    
    var discoveredWords: Set<String> {
        get {
            guard let discoveredWordsData = discoveredWordsData,
                  let decoded = try? JSONDecoder().decode([String].self, from: discoveredWordsData) else {
                return []
            }
            return Set(decoded)
        }
        set {
            discoveredWordsData = try? JSONEncoder().encode(Array(newValue))
        }
    }
    
    // MARK: - Helper Methods
    
    func toStorySession() -> StorySession? {
        guard let story = story,
              let sessionId = id else { return nil }
        // Use existing UUID from Core Data to preserve session identity
        return StorySession(
            id: sessionId,
            story: story,
            currentPageIndex: Int(currentPageIndex),
            answers: answers,
            correctAnswers: Int(correctAnswers),
            isComplete: isComplete,
            discoveredWords: discoveredWords
        )
    }
    
    func updateFromSession(_ session: StorySession) {
        currentPageIndex = Int32(session.currentPageIndex)
        answers = session.answers
        correctAnswers = Int32(session.correctAnswers)
        isComplete = session.isComplete
        discoveredWords = session.discoveredWords
        score = Int32(session.score)
    }
}


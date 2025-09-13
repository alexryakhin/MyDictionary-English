//
//  Lesson+CoreDataClass.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

@objc(CDLesson)
class CDLesson: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Convert to Lesson model
    var toLesson: LearningModels.Lesson {
        return LearningModels.Lesson(
            id: id?.uuidString ?? UUID().uuidString,
            learningPlanId: learningPlanId ?? "",
            type: LearningModels.LessonType(rawValue: type ?? "vocabulary") ?? .vocabulary,
            day: Int(day),
            week: Int(week),
            theme: theme ?? "",
            title: title ?? "",
            content: decodeContent(),
            estimatedDuration: Int(estimatedDuration),
            difficulty: difficulty ?? "beginner",
            status: LearningModels.LessonStatus(rawValue: status ?? "not_started") ?? .notStarted,
            completedAt: completedAt,
            timeSpent: Int(timeSpent),
            score: score,
            createdAt: createdAt ?? Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func decodeContent() -> LearningModels.LessonContent {
        guard let data = content else { 
            return LearningModels.LessonContent(objectives: [], vocabulary: nil, grammar: nil, exercises: [], examples: [], culturalNotes: nil)
        }
        do {
            return try JSONDecoder().decode(LearningModels.LessonContent.self, from: data)
        } catch {
            print("❌ [CDLesson] Error decoding content: \(error)")
            return LearningModels.LessonContent(objectives: [], vocabulary: nil, grammar: nil, exercises: [], examples: [], culturalNotes: nil)
        }
    }
    
    // MARK: - Factory Methods
    
    /// Create a new Lesson entity from Lesson model
    static func create(from lesson: LearningModels.Lesson, in context: NSManagedObjectContext) -> CDLesson {
        let entity = CDLesson(context: context)
        entity.id = UUID(uuidString: lesson.id) ?? UUID()
        entity.learningPlanId = lesson.learningPlanId
        entity.type = lesson.type.rawValue
        entity.day = Int16(lesson.day)
        entity.week = Int16(lesson.week)
        entity.theme = lesson.theme
        entity.title = lesson.title
        entity.content = encodeContent(lesson.content)
        entity.estimatedDuration = Int16(lesson.estimatedDuration)
        entity.difficulty = lesson.difficulty
        entity.status = lesson.status.rawValue
        entity.completedAt = lesson.completedAt
        entity.timeSpent = Int16(lesson.timeSpent)
        entity.score = lesson.score
        entity.createdAt = lesson.createdAt
        entity.syncedAt = nil
        return entity
    }
    
    private static func encodeContent(_ content: LearningModels.LessonContent) -> Data? {
        do {
            return try JSONEncoder().encode(content)
        } catch {
            print("❌ [CDLesson] Error encoding content: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Methods
    
    /// Update the lesson with new data
    func update(from lesson: LearningModels.Lesson) {
        self.learningPlanId = lesson.learningPlanId
        self.type = lesson.type.rawValue
        self.day = Int16(lesson.day)
        self.week = Int16(lesson.week)
        self.theme = lesson.theme
        self.title = lesson.title
        self.content = Self.encodeContent(lesson.content)
        self.estimatedDuration = Int16(lesson.estimatedDuration)
        self.difficulty = lesson.difficulty
        self.status = lesson.status.rawValue
        self.completedAt = lesson.completedAt
        self.timeSpent = Int16(lesson.timeSpent)
        self.score = lesson.score
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark lesson as completed
    func markAsCompleted(timeSpent: Int, score: Float) {
        self.status = LearningModels.LessonStatus.completed.rawValue
        self.completedAt = Date()
        self.timeSpent = Int16(timeSpent)
        self.score = score
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark as synced
    func markAsSynced() {
        self.syncedAt = Date()
    }
    
    /// Check if lesson needs sync
    var needsSync: Bool {
        return syncedAt == nil
    }
}


//
//  Assessment+CoreDataClass.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

@objc(CDAssessment)
class CDAssessment: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Convert to Assessment model
    var toAssessment: LearningAssessment {
        return LearningAssessment(
            id: id?.uuidString ?? UUID().uuidString,
            type: LearningAssessmentType(rawValue: type ?? "daily_progress") ?? .dailyProgress,
            level: level ?? "beginner",
            targetLevel: targetLevel ?? "elementary",
            questions: decodeQuestions(),
            passingCriteria: decodePassingCriteria(),
            score: score,
            passed: passed,
            results: decodeResults(),
            completedAt: completedAt,
            createdAt: createdAt ?? Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func decodeQuestions() -> [LearningAssessmentQuestion] {
        guard let data = questions else { return [] }
        do {
            return try JSONDecoder().decode([LearningAssessmentQuestion].self, from: data)
        } catch {
            print("❌ [CDAssessment] Error decoding questions: \(error)")
            return []
        }
    }
    
    private func decodePassingCriteria() -> LearningModels.AssessmentPassingCriteria {
        guard let data = passingCriteria else { 
            return LearningModels.AssessmentPassingCriteria(overall: 80, vocabulary: 70, grammar: 70, reading: 70, writing: 70)
        }
        do {
            return try JSONDecoder().decode(LearningModels.AssessmentPassingCriteria.self, from: data)
        } catch {
            print("❌ [CDAssessment] Error decoding passing criteria: \(error)")
            return LearningModels.AssessmentPassingCriteria(overall: 80, vocabulary: 70, grammar: 70, reading: 70, writing: 70)
        }
    }
    
    private func decodeResults() -> LearningModels.AssessmentResults? {
        guard let data = results else { return nil }
        do {
            return try JSONDecoder().decode(LearningModels.AssessmentResults.self, from: data)
        } catch {
            print("❌ [CDAssessment] Error decoding results: \(error)")
            return nil
        }
    }
    
    // MARK: - Factory Methods
    
    /// Create a new Assessment entity from Assessment model
    static func create(from assessment: LearningModels.Assessment, in context: NSManagedObjectContext) -> CDAssessment {
        let entity = CDAssessment(context: context)
        entity.id = UUID(uuidString: assessment.id) ?? UUID()
        entity.type = assessment.type.rawValue
        entity.level = assessment.level
        entity.targetLevel = assessment.targetLevel
        entity.questions = encodeQuestions(assessment.questions)
        entity.passingCriteria = encodePassingCriteria(assessment.passingCriteria)
        entity.score = assessment.score
        entity.passed = assessment.passed
        entity.results = encodeResults(assessment.results)
        entity.completedAt = assessment.completedAt
        entity.createdAt = assessment.createdAt
        entity.syncedAt = nil
        return entity
    }
    
    private static func encodeQuestions(_ questions: [LearningAssessmentQuestion]) -> Data? {
        do {
            return try JSONEncoder().encode(questions)
        } catch {
            print("❌ [CDAssessment] Error encoding questions: \(error)")
            return nil
        }
    }
    
    private static func encodePassingCriteria(_ criteria: LearningModels.AssessmentPassingCriteria) -> Data? {
        do {
            return try JSONEncoder().encode(criteria)
        } catch {
            print("❌ [CDAssessment] Error encoding passing criteria: \(error)")
            return nil
        }
    }
    
    private static func encodeResults(_ results: LearningModels.AssessmentResults?) -> Data? {
        guard let results = results else { return nil }
        do {
            return try JSONEncoder().encode(results)
        } catch {
            print("❌ [CDAssessment] Error encoding results: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Methods
    
    /// Update the assessment with new data
    func update(from assessment: LearningModels.Assessment) {
        self.type = assessment.type.rawValue
        self.level = assessment.level
        self.targetLevel = assessment.targetLevel
        self.questions = Self.encodeQuestions(assessment.questions)
        self.passingCriteria = Self.encodePassingCriteria(assessment.passingCriteria)
        self.score = assessment.score
        self.passed = assessment.passed
        self.results = Self.encodeResults(assessment.results)
        self.completedAt = assessment.completedAt
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark assessment as completed
    func markAsCompleted(score: Float, passed: Bool, results: LearningModels.AssessmentResults) {
        self.score = score
        self.passed = passed
        self.results = Self.encodeResults(results)
        self.completedAt = Date()
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark as synced
    func markAsSynced() {
        self.syncedAt = Date()
    }
    
    /// Check if assessment needs sync
    var needsSync: Bool {
        return syncedAt == nil
    }
}


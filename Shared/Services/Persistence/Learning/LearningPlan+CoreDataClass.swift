//
//  LearningPlan+CoreDataClass.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

@objc(CDLearningPlan)
class CDLearningPlan: NSManagedObject {
    
    // MARK: - Computed Properties
    
    /// Convert to LearningPlan model
    var toLearningPlan: LearningPlan {
        return LearningPlan(
            id: id?.uuidString ?? UUID().uuidString,
            targetLanguage: targetLanguage ?? "english",
            currentLevel: currentLevel ?? "beginner",
            totalDuration: Int(totalDuration),
            dailyStructure: decodeDailyStructure(),
            weeklyThemes: decodeWeeklyThemes(),
            assessmentCheckpoints: decodeAssessmentCheckpoints(),
            createdAt: createdAt ?? Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func decodeDailyStructure() -> LearningModels.DailyStructure {
        guard let data = dailyStructure else { 
            return LearningModels.DailyStructure(vocabulary: 15, grammar: 10, speaking: 10, writing: 5, reading: 10)
        }
        do {
            return try JSONDecoder().decode(LearningModels.DailyStructure.self, from: data)
        } catch {
            print("❌ [CDLearningPlan] Error decoding daily structure: \(error)")
            return LearningModels.DailyStructure(vocabulary: 15, grammar: 10, speaking: 10, writing: 5, reading: 10)
        }
    }
    
    private func decodeWeeklyThemes() -> [LearningModels.WeeklyTheme] {
        guard let data = weeklyThemes else { return [] }
        do {
            return try JSONDecoder().decode([LearningModels.WeeklyTheme].self, from: data)
        } catch {
            print("❌ [CDLearningPlan] Error decoding weekly themes: \(error)")
            return []
        }
    }
    
    private func decodeAssessmentCheckpoints() -> [LearningModels.LearningAssessmentCheckpoint] {
        guard let data = assessmentCheckpoints else { return [] }
        do {
            return try JSONDecoder().decode([LearningModels.LearningAssessmentCheckpoint].self, from: data)
        } catch {
            print("❌ [CDLearningPlan] Error decoding assessment checkpoints: \(error)")
            return []
        }
    }
    
    // MARK: - Factory Methods
    
    /// Create a new LearningPlan entity from LearningPlan model
    static func create(from plan: LearningModels.LearningPlan, in context: NSManagedObjectContext) -> CDLearningPlan {
        let entity = CDLearningPlan(context: context)
        entity.id = UUID(uuidString: plan.id) ?? UUID()
        entity.targetLanguage = plan.targetLanguage
        entity.currentLevel = plan.currentLevel
        entity.totalDuration = Int32(plan.totalDuration)
        entity.dailyStructure = encodeDailyStructure(plan.dailyStructure)
        entity.weeklyThemes = encodeWeeklyThemes(plan.weeklyThemes)
        entity.assessmentCheckpoints = encodeAssessmentCheckpoints(plan.assessmentCheckpoints)
        entity.createdAt = plan.createdAt
        entity.updatedAt = Date()
        entity.syncedAt = nil
        return entity
    }
    
    private static func encodeDailyStructure(_ structure: LearningModels.DailyStructure) -> Data? {
        do {
            return try JSONEncoder().encode(structure)
        } catch {
            print("❌ [CDLearningPlan] Error encoding daily structure: \(error)")
            return nil
        }
    }
    
    private static func encodeWeeklyThemes(_ themes: [LearningModels.WeeklyTheme]) -> Data? {
        do {
            return try JSONEncoder().encode(themes)
        } catch {
            print("❌ [CDLearningPlan] Error encoding weekly themes: \(error)")
            return nil
        }
    }
    
    private static func encodeAssessmentCheckpoints(_ checkpoints: [LearningModels.LearningAssessmentCheckpoint]) -> Data? {
        do {
            return try JSONEncoder().encode(checkpoints)
        } catch {
            print("❌ [CDLearningPlan] Error encoding assessment checkpoints: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Methods
    
    /// Update the plan with new data
    func update(from plan: LearningModels.LearningPlan) {
        self.targetLanguage = plan.targetLanguage
        self.currentLevel = plan.currentLevel
        self.totalDuration = Int32(plan.totalDuration)
        self.dailyStructure = Self.encodeDailyStructure(plan.dailyStructure)
        self.weeklyThemes = Self.encodeWeeklyThemes(plan.weeklyThemes)
        self.assessmentCheckpoints = Self.encodeAssessmentCheckpoints(plan.assessmentCheckpoints)
        self.updatedAt = Date()
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark as synced
    func markAsSynced() {
        self.syncedAt = Date()
    }
    
    /// Check if plan needs sync
    var needsSync: Bool {
        return syncedAt == nil
    }
}


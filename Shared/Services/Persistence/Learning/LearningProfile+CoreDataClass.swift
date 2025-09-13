//
//  LearningProfile+CoreDataClass.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

@objc(CDLearningProfile)
final class CDLearningProfile: NSManagedObject {

    // MARK: - Computed Properties
    
    /// Convert to LearningProfile model
    var toLearningProfile: LearningProfile {
        return LearningProfile(
            id: id?.uuidString ?? UUID().uuidString,
            targetLanguage: InputLanguage(rawValue: targetLanguage ?? "english") ?? .english,
            currentLevel: LanguageLevel(rawValue: currentLevel ?? "beginner") ?? .beginner,
            interests: decodeInterests(),
            learningGoals: decodeGoals(),
            timeCommitment: TimeCommitment(rawValue: timeCommitment ?? "casual") ?? .casual,
            learningStyle: LearningStyle(rawValue: learningStyle ?? "balanced") ?? .balanced,
            nativeLanguage: InputLanguage(rawValue: nativeLanguage ?? "english") ?? .english,
            motivation: LearningMotivation(rawValue: motivation ?? "personal") ?? .personal,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    // MARK: - Helper Methods
    
    private func decodeInterests() -> [LearningInterest] {
        guard let data = interests else { return [] }
        do {
            return try JSONDecoder().decode([LearningInterest].self, from: data)
        } catch {
            print("❌ [CDLearningProfile] Error decoding interests: \(error)")
            return []
        }
    }
    
    private func decodeGoals() -> [LearningGoal] {
        guard let data = goals else { return [] }
        do {
            return try JSONDecoder().decode([LearningGoal].self, from: data)
        } catch {
            print("❌ [CDLearningProfile] Error decoding goals: \(error)")
            return []
        }
    }
    
    // MARK: - Factory Methods
    
    /// Create a new LearningProfile entity from LearningProfile model
    static func create(from profile: LearningProfile, in context: NSManagedObjectContext) -> CDLearningProfile {
        let entity = CDLearningProfile(context: context)
        entity.id = UUID(uuidString: profile.id) ?? UUID()
        entity.targetLanguage = profile.targetLanguage.rawValue
        entity.currentLevel = profile.currentLevel.rawValue
        entity.interests = encodeInterests(profile.interests)
        entity.goals = encodeGoals(profile.learningGoals)
        entity.timeCommitment = profile.timeCommitment.rawValue
        entity.learningStyle = profile.learningStyle.rawValue
        entity.nativeLanguage = profile.nativeLanguage.rawValue
        entity.motivation = profile.motivation.rawValue
        entity.createdAt = profile.createdAt
        entity.updatedAt = profile.updatedAt
        entity.syncedAt = nil
        return entity
    }
    
    private static func encodeInterests(_ interests: [LearningInterest]) -> Data? {
        do {
            return try JSONEncoder().encode(interests)
        } catch {
            print("❌ [CDLearningProfile] Error encoding interests: \(error)")
            return nil
        }
    }
    
    private static func encodeGoals(_ goals: [LearningGoal]) -> Data? {
        do {
            return try JSONEncoder().encode(goals)
        } catch {
            print("❌ [CDLearningProfile] Error encoding goals: \(error)")
            return nil
        }
    }
    
    // MARK: - Update Methods
    
    /// Update the profile with new data
    func update(from profile: LearningProfile) {
        self.targetLanguage = profile.targetLanguage.rawValue
        self.currentLevel = profile.currentLevel.rawValue
        self.interests = Self.encodeInterests(profile.interests)
        self.goals = Self.encodeGoals(profile.learningGoals)
        self.timeCommitment = profile.timeCommitment.rawValue
        self.learningStyle = profile.learningStyle.rawValue
        self.nativeLanguage = profile.nativeLanguage.rawValue
        self.motivation = profile.motivation.rawValue
        self.updatedAt = Date()
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark as synced
    func markAsSynced() {
        self.syncedAt = Date()
    }
    
    /// Check if profile needs sync
    var needsSync: Bool {
        return syncedAt == nil
    }
}

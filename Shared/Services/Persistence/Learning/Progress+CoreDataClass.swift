//
//  Progress+CoreDataClass.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

@objc(CDProgress)
final class CDProgress: NSManagedObject {

    // MARK: - Computed Properties
    
    /// Convert to Progress model
    var toProgress: LearningModels.Progress {
        return LearningModels.Progress(
            id: id?.uuidString ?? UUID().uuidString,
            currentDay: Int(currentDay),
            totalDaysCompleted: Int(totalDaysCompleted),
            totalLessonsCompleted: Int(totalLessonsCompleted),
            totalWordsLearned: Int(totalWordsLearned),
            totalStudyTime: Int(totalStudyTime),
            currentStreak: Int(currentStreak),
            longestStreak: Int(longestStreak),
            lastStudyDate: lastStudyDate,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    // MARK: - Factory Methods
    
    /// Create a new Progress entity from Progress model
    static func create(from progress: LearningModels.Progress, in context: NSManagedObjectContext) -> CDProgress {
        let entity = CDProgress(context: context)
        entity.id = UUID(uuidString: progress.id) ?? UUID()
        entity.currentDay = Int32(progress.currentDay)
        entity.totalDaysCompleted = Int32(progress.totalDaysCompleted)
        entity.totalLessonsCompleted = Int32(progress.totalLessonsCompleted)
        entity.totalWordsLearned = Int32(progress.totalWordsLearned)
        entity.totalStudyTime = Int32(progress.totalStudyTime)
        entity.currentStreak = Int32(progress.currentStreak)
        entity.longestStreak = Int32(progress.longestStreak)
        entity.lastStudyDate = progress.lastStudyDate
        entity.createdAt = progress.createdAt
        entity.updatedAt = progress.updatedAt
        entity.syncedAt = nil
        return entity
    }
    
    // MARK: - Update Methods
    
    /// Update the progress with new data
    func update(from progress: LearningModels.Progress) {
        self.currentDay = Int32(progress.currentDay)
        self.totalDaysCompleted = Int32(progress.totalDaysCompleted)
        self.totalLessonsCompleted = Int32(progress.totalLessonsCompleted)
        self.totalWordsLearned = Int32(progress.totalWordsLearned)
        self.totalStudyTime = Int32(progress.totalStudyTime)
        self.currentStreak = Int32(progress.currentStreak)
        self.longestStreak = Int32(progress.longestStreak)
        self.lastStudyDate = progress.lastStudyDate
        self.updatedAt = Date()
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Update daily progress
    func updateDailyProgress(lessonsCompleted: Int, wordsLearned: Int, studyTime: Int) {
        self.totalLessonsCompleted += Int32(lessonsCompleted)
        self.totalWordsLearned += Int32(wordsLearned)
        self.totalStudyTime += Int32(studyTime)
        self.lastStudyDate = Date()
        self.updatedAt = Date()
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Update streak
    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastStudy = lastStudyDate.map { Calendar.current.startOfDay(for: $0) }
        
        if let lastStudy = lastStudy {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastStudy, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day
                self.currentStreak += 1
            } else if daysBetween > 1 {
                // Streak broken
                self.currentStreak = 1
            }
            // daysBetween == 0 means same day, no change
        } else {
            // First study day
            self.currentStreak = 1
        }
        
        // Update longest streak if current is higher
        if self.currentStreak > self.longestStreak {
            self.longestStreak = self.currentStreak
        }
        
        self.updatedAt = Date()
        self.syncedAt = nil // Mark as needing sync
    }
    
    /// Mark as synced
    func markAsSynced() {
        self.syncedAt = Date()
    }
    
    /// Check if progress needs sync
    var needsSync: Bool {
        return syncedAt == nil
    }
}


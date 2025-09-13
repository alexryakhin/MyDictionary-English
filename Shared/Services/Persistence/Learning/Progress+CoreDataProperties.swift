//
//  Progress+CoreDataProperties.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

extension CDProgress {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDProgress> {
        return NSFetchRequest<CDProgress>(entityName: "Progress")
    }

    @NSManaged var id: UUID?
    @NSManaged var currentDay: Int32
    @NSManaged var totalDaysCompleted: Int32
    @NSManaged var totalLessonsCompleted: Int32
    @NSManaged var totalWordsLearned: Int32
    @NSManaged var totalStudyTime: Int32
    @NSManaged var currentStreak: Int32
    @NSManaged var longestStreak: Int32
    @NSManaged var lastStudyDate: Date?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var syncedAt: Date?
    
    // Relationships
    @NSManaged var learningProfile: CDLearningProfile?

}

//
//  LearningPlan+CoreDataProperties.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

extension CDLearningPlan {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDLearningPlan> {
        return NSFetchRequest<CDLearningPlan>(entityName: "LearningPlan")
    }

    @NSManaged var id: UUID?
    @NSManaged var targetLanguage: String?
    @NSManaged var currentLevel: String?
    @NSManaged var totalDuration: Int32
    @NSManaged var dailyStructure: Data?
    @NSManaged var weeklyThemes: Data?
    @NSManaged var assessmentCheckpoints: Data?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var syncedAt: Date?
    
    // Relationships
    @NSManaged var learningProfile: CDLearningProfile?
    @NSManaged var lessons: NSSet?

}

// MARK: Generated accessors for lessons
extension CDLearningPlan {

    @objc(addLessonsObject:)
    @NSManaged func addToLessons(_ value: CDLesson)

    @objc(removeLessonsObject:)
    @NSManaged func removeFromLessons(_ value: CDLesson)

    @objc(addLessons:)
    @NSManaged func addToLessons(_ values: NSSet)

    @objc(removeLessons:)
    @NSManaged func removeFromLessons(_ values: NSSet)

}

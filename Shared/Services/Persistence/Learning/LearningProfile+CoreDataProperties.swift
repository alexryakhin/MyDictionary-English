//
//  LearningProfile+CoreDataProperties.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

extension CDLearningProfile {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDLearningProfile> {
        return NSFetchRequest<CDLearningProfile>(entityName: "LearningProfile")
    }

    @NSManaged var id: UUID?
    @NSManaged var targetLanguage: String?
    @NSManaged var currentLevel: String?
    @NSManaged var interests: Data?
    @NSManaged var goals: Data?
    @NSManaged var timeCommitment: String?
    @NSManaged var learningStyle: String?
    @NSManaged var nativeLanguage: String?
    @NSManaged var motivation: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var syncedAt: Date?
    
    // Relationships
    @NSManaged var learningPlan: CDLearningPlan?
    @NSManaged var lessons: NSSet?
    @NSManaged var assessments: NSSet?
    @NSManaged var progress: CDProgress?

}

// MARK: Generated accessors for lessons
extension CDLearningProfile {

    @objc(addLessonsObject:)
    @NSManaged func addToLessons(_ value: CDLesson)

    @objc(removeLessonsObject:)
    @NSManaged func removeFromLessons(_ value: CDLesson)

    @objc(addLessons:)
    @NSManaged func addToLessons(_ values: NSSet)

    @objc(removeLessons:)
    @NSManaged func removeFromLessons(_ values: NSSet)

}

// MARK: Generated accessors for assessments
extension CDLearningProfile {

    @objc(addAssessmentsObject:)
    @NSManaged func addToAssessments(_ value: CDAssessment)

    @objc(removeAssessmentsObject:)
    @NSManaged func removeFromAssessments(_ value: CDAssessment)

    @objc(addAssessments:)
    @NSManaged func addToAssessments(_ values: NSSet)

    @objc(removeAssessments:)
    @NSManaged func removeFromAssessments(_ values: NSSet)

}

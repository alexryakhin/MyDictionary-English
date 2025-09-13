//
//  Assessment+CoreDataProperties.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

extension CDAssessment {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDAssessment> {
        return NSFetchRequest<CDAssessment>(entityName: "Assessment")
    }

    @NSManaged var id: UUID?
    @NSManaged var type: String?
    @NSManaged var level: String?
    @NSManaged var targetLevel: String?
    @NSManaged var questions: Data?
    @NSManaged var passingCriteria: Data?
    @NSManaged var score: Float
    @NSManaged var passed: Bool
    @NSManaged var results: Data?
    @NSManaged var completedAt: Date?
    @NSManaged var createdAt: Date?
    @NSManaged var syncedAt: Date?
    
    // Relationships
    @NSManaged var learningProfile: CDLearningProfile?

}

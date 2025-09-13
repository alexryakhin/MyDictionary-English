//
//  Lesson+CoreDataProperties.swift
//  My Dictionary
//
//  Created by AI Learning Development Team on 3/9/25.
//

import Foundation
import CoreData

extension CDLesson {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDLesson> {
        return NSFetchRequest<CDLesson>(entityName: "Lesson")
    }

    @NSManaged var id: UUID?
    @NSManaged var learningPlanId: String?
    @NSManaged var type: String?
    @NSManaged var day: Int16
    @NSManaged var week: Int16
    @NSManaged var theme: String?
    @NSManaged var title: String?
    @NSManaged var content: Data?
    @NSManaged var estimatedDuration: Int16
    @NSManaged var difficulty: String?
    @NSManaged var status: String?
    @NSManaged var completedAt: Date?
    @NSManaged var timeSpent: Int16
    @NSManaged var score: Float
    @NSManaged var createdAt: Date?
    @NSManaged var syncedAt: Date?
    
    // Relationships
    @NSManaged var learningProfile: CDLearningProfile?
    @NSManaged var learningPlan: CDLearningPlan?

}

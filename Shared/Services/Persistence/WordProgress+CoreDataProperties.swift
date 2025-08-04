//
//  WordProgress+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDWordProgress {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWordProgress> {
        return NSFetchRequest<CDWordProgress>(entityName: "WordProgress")
    }

    @NSManaged public var averageResponseTime: Double
    @NSManaged public var consecutiveCorrect: Int32
    @NSManaged public var correctAttempts: Int32
    @NSManaged public var difficultyScore: Double
    @NSManaged public var id: UUID?
    @NSManaged public var lastPracticed: Date?
    @NSManaged public var masteryLevel: String?
    @NSManaged public var totalAttempts: Int32
    @NSManaged public var wordId: String?

}

extension CDWordProgress : Identifiable {

} 
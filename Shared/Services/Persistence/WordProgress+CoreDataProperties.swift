//
//  WordProgress+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDWordProgress {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDWordProgress> {
        return NSFetchRequest<CDWordProgress>(entityName: "WordProgress")
    }

    @NSManaged var averageResponseTime: Double
    @NSManaged var consecutiveCorrect: Int32
    @NSManaged var correctAttempts: Int32
    @NSManaged var difficultyScore: Double
    @NSManaged var id: UUID?
    @NSManaged var lastPracticed: Date?
    @NSManaged var masteryLevel: String?
    @NSManaged var totalAttempts: Int32
    @NSManaged var wordId: String?

}

extension CDWordProgress : Identifiable {

} 

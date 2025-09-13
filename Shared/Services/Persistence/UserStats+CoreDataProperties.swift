//
//  UserStats+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDUserStats {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDUserStats> {
        return NSFetchRequest<CDUserStats>(entityName: "UserStats")
    }

    @NSManaged var averageAccuracy: Double
    @NSManaged var currentStreak: Int32
    @NSManaged var id: UUID?
    @NSManaged var lastPracticeDate: Date?
    @NSManaged var longestStreak: Int32
    @NSManaged var totalPracticeTime: Double
    @NSManaged var totalSessions: Int32
    @NSManaged var totalWordsStudied: Int32
    @NSManaged var vocabularySize: Int32

}

extension CDUserStats : Identifiable {

}

//
//  UserStats+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDUserStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserStats> {
        return NSFetchRequest<CDUserStats>(entityName: "UserStats")
    }

    @NSManaged public var averageAccuracy: Double
    @NSManaged public var currentStreak: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var lastPracticeDate: Date?
    @NSManaged public var longestStreak: Int32
    @NSManaged public var totalPracticeTime: Double
    @NSManaged public var totalSessions: Int32
    @NSManaged public var totalWordsStudied: Int32
    @NSManaged public var vocabularySize: Int32

}

extension CDUserStats : Identifiable {

} 
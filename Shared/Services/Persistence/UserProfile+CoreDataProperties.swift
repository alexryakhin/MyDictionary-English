//
//  UserProfile+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDUserProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userName: String?
    @NSManaged public var userType: String?
    @NSManaged public var ageGroup: String?
    @NSManaged public var learningGoalsData: Data?
    @NSManaged public var studyLanguagesData: Data?
    @NSManaged public var interestsData: Data?
    @NSManaged public var weeklyWordGoal: Int32
    @NSManaged public var preferredStudyTime: String?
    @NSManaged public var nativeLanguage: String?
    @NSManaged public var completedAt: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var skippedPaywall: Bool
    @NSManaged public var enabledNotifications: Bool
    @NSManaged public var signedIn: Bool
    @NSManaged public var lastUpdated: Date?
}

extension CDUserProfile: Identifiable {

}


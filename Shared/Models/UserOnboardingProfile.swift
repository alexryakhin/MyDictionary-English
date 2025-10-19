//
//  UserOnboardingProfile.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData
import FirebaseFirestore

struct UserOnboardingProfile: Codable {
    let id: UUID
    var cloudKitRecordID: String?
    var userName: String
    var userType: UserType
    var ageGroup: AgeGroup
    var learningGoals: [LearningGoal]
    var studyLanguages: [StudyLanguage]
    var interests: [Interest]
    var weeklyWordGoal: Int
    var preferredStudyTime: StudyTime
    var completedAt: Date
    var isCompleted: Bool
    var skippedPaywall: Bool
    var enabledNotifications: Bool
    var signedIn: Bool
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        cloudKitRecordID: String? = nil,
        userName: String = "",
        userType: UserType = .hobbyist,
        ageGroup: AgeGroup = .adult,
        learningGoals: [LearningGoal] = [],
        studyLanguages: [StudyLanguage] = [],
        interests: [Interest] = [],
        weeklyWordGoal: Int = 100,
        preferredStudyTime: StudyTime = .evening,
        completedAt: Date = Date(),
        isCompleted: Bool = false,
        skippedPaywall: Bool = false,
        enabledNotifications: Bool = false,
        signedIn: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.cloudKitRecordID = cloudKitRecordID
        self.userName = userName
        self.userType = userType
        self.ageGroup = ageGroup
        self.learningGoals = learningGoals
        self.studyLanguages = studyLanguages
        self.interests = interests
        self.weeklyWordGoal = weeklyWordGoal
        self.preferredStudyTime = preferredStudyTime
        self.completedAt = completedAt
        self.isCompleted = isCompleted
        self.skippedPaywall = skippedPaywall
        self.enabledNotifications = enabledNotifications
        self.signedIn = signedIn
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - Core Data Conversion
    
    init?(from entity: CDUserProfile) {
        guard let id = entity.id,
              let userName = entity.userName,
              let userTypeRaw = entity.userType,
              let userType = UserType(rawValue: userTypeRaw),
              let ageGroupRaw = entity.ageGroup,
              let ageGroup = AgeGroup(rawValue: ageGroupRaw),
              let studyTimeRaw = entity.preferredStudyTime,
              let studyTime = StudyTime(rawValue: studyTimeRaw),
              let completedAt = entity.completedAt,
              let lastUpdated = entity.lastUpdated else {
            return nil
        }
        
        self.id = id
        self.cloudKitRecordID = entity.cloudKitRecordID
        self.userName = userName
        self.userType = userType
        self.ageGroup = ageGroup
        self.preferredStudyTime = studyTime
        self.completedAt = completedAt
        self.lastUpdated = lastUpdated
        self.weeklyWordGoal = Int(entity.weeklyWordGoal)
        self.isCompleted = entity.isCompleted
        self.skippedPaywall = entity.skippedPaywall
        self.enabledNotifications = entity.enabledNotifications
        self.signedIn = entity.signedIn
        
        // Decode JSON arrays
        if let goalsData = entity.learningGoalsData,
           let goals = try? JSONDecoder().decode([LearningGoal].self, from: goalsData) {
            self.learningGoals = goals
        } else {
            self.learningGoals = []
        }
        
        if let languagesData = entity.studyLanguagesData,
           let languages = try? JSONDecoder().decode([StudyLanguage].self, from: languagesData) {
            self.studyLanguages = languages
        } else {
            self.studyLanguages = []
        }
        
        if let interestsData = entity.interestsData,
           let interests = try? JSONDecoder().decode([Interest].self, from: interestsData) {
            self.interests = interests
        } else {
            self.interests = []
        }
    }
    
    @discardableResult
    func saveToCoreData() throws -> CDUserProfile {
        let context = CoreDataService.shared.context
        
        // Try to find existing profile by cloudKitRecordID first (most reliable)
        let fetchRequest: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        
        if let cloudKitRecordID = self.cloudKitRecordID {
            // If we have a cloudKitRecordID, look for existing profile with same ID
            fetchRequest.predicate = NSPredicate(format: "cloudKitRecordID == %@", cloudKitRecordID)
        } else {
            // If no cloudKitRecordID, look for any existing profile
            // This handles the case where profile was created before CloudKit ID was set
        }
        
        let existingProfiles = try context.fetch(fetchRequest)
        
        let entity: CDUserProfile
        if let existing = existingProfiles.first {
            // Update existing profile
            entity = existing
        } else {
            // No existing profile found, create new one
            entity = CDUserProfile(context: context)
            entity.id = self.id
        }
        
        // Update properties
        entity.cloudKitRecordID = self.cloudKitRecordID
        entity.userName = self.userName
        entity.userType = self.userType.rawValue
        entity.ageGroup = self.ageGroup.rawValue
        entity.weeklyWordGoal = Int32(self.weeklyWordGoal)
        entity.preferredStudyTime = self.preferredStudyTime.rawValue
        entity.completedAt = self.completedAt
        entity.isCompleted = self.isCompleted
        entity.skippedPaywall = self.skippedPaywall
        entity.enabledNotifications = self.enabledNotifications
        entity.signedIn = self.signedIn
        entity.lastUpdated = self.lastUpdated
        
        // Encode JSON arrays
        entity.learningGoalsData = try JSONEncoder().encode(self.learningGoals)
        entity.studyLanguagesData = try JSONEncoder().encode(self.studyLanguages)
        entity.interestsData = try JSONEncoder().encode(self.interests)
        
        try context.save()
        return entity
    }
    
    // MARK: - Firestore Conversion
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "userName": userName,
            "userType": userType.rawValue,
            "ageGroup": ageGroup.rawValue,
            "weeklyWordGoal": weeklyWordGoal,
            "preferredStudyTime": preferredStudyTime.rawValue,
            "completedAt": Timestamp(date: completedAt),
            "isCompleted": isCompleted,
            "skippedPaywall": skippedPaywall,
            "enabledNotifications": enabledNotifications,
            "signedIn": signedIn,
            "lastUpdated": Timestamp(date: lastUpdated)
        ]
        
        if let cloudKitRecordID = cloudKitRecordID {
            data["cloudKitRecordID"] = cloudKitRecordID
        }
        
        // Add arrays as strings
        data["learningGoals"] = learningGoals.map { $0.rawValue }
        data["studyLanguages"] = studyLanguages.map { ["language": $0.language.rawValue, "level": $0.proficiencyLevel.rawValue] }
        data["interests"] = interests.map { $0.rawValue }
        
        return data
    }
    
    func syncToFirestore() async throws {
        guard let userEmail = AuthenticationService.shared.currentUser?.email else {
            return
        }
        
        let db = Firestore.firestore()
        let data = toFirestoreData()
        
        try await db.collection("users")
            .document(userEmail)
            .setData(["onboardingProfile": data], merge: true)
    }
    
    // MARK: - Computed Properties
    
    var dailyWordGoal: Int {
        return weeklyWordGoal / 7
    }
    
    var estimatedDailyMinutes: Int {
        switch weeklyWordGoal {
        case 0..<75:
            return 10
        case 75..<150:
            return 20
        case 150..<250:
            return 40
        default:
            return 60
        }
    }
    
    var primaryLanguage: InputLanguage? {
        return studyLanguages.first?.language
    }
    
    var isComplete: Bool {
        // Profile is marked complete only when user finishes entire onboarding flow
        return isCompleted
    }
}


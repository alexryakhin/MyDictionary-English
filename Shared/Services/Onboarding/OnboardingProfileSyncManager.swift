//
//  OnboardingProfileSyncManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData
import CloudKit

final class OnboardingProfileSyncManager {
    
    static let shared = OnboardingProfileSyncManager()
    
    private let coreDataService = CoreDataService.shared
    private let cloudKitService = CloudKitService.shared
    private let container = CKContainer.default()
    
    private init() {}
    
    // MARK: - Profile Check
    
    /// Checks for existing profile in iCloud/Core Data
    /// Returns true if a profile exists (either locally synced or in CloudKit)
    func checkForExistingProfile() async -> Bool {
        // First check local Core Data for existing profile
        if hasLocalProfile() {
            return true
        }
        
        // Check if iCloud is available
        let isAvailable = await cloudKitService.checkAvailabilityWithTimeout(timeout: 5.0)
        guard isAvailable else {
            return false
        }
        
        // Enforce single profile rule
        await enforceSingleProfile()
        
        // Check again after enforcement
        return hasLocalProfile()
    }
    
    /// Checks if a profile exists in local Core Data
    func hasLocalProfile() -> Bool {
        return coreDataService.hasUserProfile()
    }
    
    // MARK: - Single Profile Enforcement
    
    /// Enforces single profile rule by querying CloudKit and removing duplicates
    func enforceSingleProfile() async {
        do {
            let profiles = try await fetchAllProfilesFromCloudKit()
            
            guard !profiles.isEmpty else {
                return
            }
            
            // If multiple profiles exist, keep the most recent one
            if profiles.count > 1 {
                try await cleanupDuplicateProfiles(profiles)
            }
            
            // Sync the single profile to local Core Data
            if let profile = profiles.first {
                await syncProfileToLocal(profile)
            }
            
        } catch {
            logError("Failed to enforce single profile: \(error)")
        }
    }
    
    // MARK: - CloudKit Operations
    
    /// Fetches all UserProfile records from CloudKit
    private func fetchAllProfilesFromCloudKit() async throws -> [CKRecord] {
        let database = container.privateCloudDatabase
        let query = CKQuery(recordType: "CD_UserProfile", predicate: NSPredicate(value: true))
        
        // Sort by lastUpdated (most recent first)
        query.sortDescriptors = [NSSortDescriptor(key: "CD_lastUpdated", ascending: false)]
        
        return try await withCheckedThrowingContinuation { continuation in
            database.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: records ?? [])
                }
            }
        }
    }
    
    /// Removes duplicate profiles, keeping only the most recent one
    private func cleanupDuplicateProfiles(_ profiles: [CKRecord]) async throws {
        guard profiles.count > 1 else { return }
        
        // Keep the first one (most recent due to sorting)
        let profilesToDelete = Array(profiles.dropFirst())
        
        let database = container.privateCloudDatabase
        
        for record in profilesToDelete {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                database.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        logError("Failed to delete duplicate profile: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
        
        logInfo("Cleaned up \(profilesToDelete.count) duplicate profile(s)")
    }
    
    /// Syncs a CloudKit profile record to local Core Data
    private func syncProfileToLocal(_ record: CKRecord) async {
        await MainActor.run {
            let context = coreDataService.context
            
            // Check if profile already exists locally
            let fetchRequest: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
            
            do {
                let existingProfiles = try context.fetch(fetchRequest)
                let entity: CDUserProfile
                
                if let existing = existingProfiles.first {
                    entity = existing
                } else {
                    entity = CDUserProfile(context: context)
                    entity.id = UUID()
                }
                
                // Update entity with CloudKit data
                entity.cloudKitRecordID = record.recordID.recordName
                entity.userName = record["CD_userName"] as? String
                entity.userType = record["CD_userType"] as? String
                entity.ageGroup = record["CD_ageGroup"] as? String
                entity.weeklyWordGoal = (record["CD_weeklyWordGoal"] as? Int32) ?? 100
                entity.preferredStudyTime = record["CD_preferredStudyTime"] as? String
                entity.completedAt = record["CD_completedAt"] as? Date
                entity.isCompleted = (record["CD_isCompleted"] as? Int64) == 1
                entity.skippedPaywall = (record["CD_skippedPaywall"] as? Int64) == 1
                entity.enabledNotifications = (record["CD_enabledNotifications"] as? Int64) == 1
                entity.signedIn = (record["CD_signedIn"] as? Int64) == 1
                entity.lastUpdated = record["CD_lastUpdated"] as? Date ?? Date()
                entity.learningGoalsData = record["CD_learningGoalsData"] as? Data
                entity.studyLanguagesData = record["CD_studyLanguagesData"] as? Data
                entity.interestsData = record["CD_interestsData"] as? Data
                
                try context.save()
                
                // Mark onboarding as completed in UserDefaults
                UDService.hasCompletedOnboarding = true
                
                logInfo("Synced profile from CloudKit to local Core Data")
                
            } catch {
                logError("Failed to sync profile to local: \(error)")
            }
        }
    }
    
    // MARK: - Profile Setup
    
    /// Gets CloudKit record ID for the current user
    func getCloudKitRecordID() async -> String? {
        return await cloudKitService.fetchUserRecordIDWithTimeout(timeout: 5.0)
    }
    
    /// Sets CloudKit record ID on a profile
    func setCloudKitRecordID(for profile: inout UserOnboardingProfile) async {
        if let recordID = await cloudKitService.fetchUserRecordIDWithTimeout(timeout: 5.0) {
            profile.cloudKitRecordID = recordID
        }
    }
    
    // MARK: - Manual Cleanup
    
    /// Manually cleans up duplicate profiles in both Core Data and CloudKit
    func cleanupAllDuplicates() async {
        // First clean up local Core Data duplicates
        await MainActor.run {
            let context = self.coreDataService.context
            let fetchRequest: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
            
            do {
                let allProfiles = try context.fetch(fetchRequest)
                
                if allProfiles.count > 1 {
                    // Sort by lastUpdated (most recent first)
                    let sortedProfiles = allProfiles.sorted { 
                        ($0.lastUpdated ?? Date.distantPast) > ($1.lastUpdated ?? Date.distantPast) 
                    }
                    
                    // Keep the most recent one, delete all others
                    for duplicate in sortedProfiles.dropFirst() {
                        context.delete(duplicate)
                    }
                    
                    try context.save()
                    logInfo("Manually cleaned up \(sortedProfiles.count - 1) duplicate profile(s) in Core Data")
                }
            } catch {
                logError("Failed to manually cleanup duplicate profiles: \(error)")
            }
        }
        
        // Then clean up CloudKit duplicates
        await enforceSingleProfile()
    }
}


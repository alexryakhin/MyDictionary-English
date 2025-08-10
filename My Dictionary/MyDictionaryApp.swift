//
//  MyDictionaryApp.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Firebase

@main
struct MyDictionaryApp: App {

    @AppStorage(UDKeys.dailyRemindersEnabled) var dailyRemindersEnabled: Bool = false
    @AppStorage(UDKeys.difficultWordsEnabled) var difficultWordsEnabled: Bool = false

    init() {
        FirebaseApp.configure()
        
        // Configure Firestore for offline persistence
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
        
        AnalyticsService.shared.logEvent(.appOpened)
        
        // Debug Firebase configuration
        FirebaseDebugService.shared.checkFirebaseConfiguration()
        FirebaseDebugService.shared.checkAuthenticationStatus()
        

        
        // Sync from Firestore on app startup and start real-time listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let userId = AuthenticationService.shared.userId {
                print("🔄 [App] Triggering initial sync from Firestore for userId: \(userId)")
                Task {
                    do {
                        try await DataSyncService.shared.syncFirestoreToCoreData(userId: userId)
                        print("✅ [App] Initial sync from Firestore completed successfully")
                    } catch {
                        print("❌ [App] Initial sync from Firestore failed: \(error.localizedDescription)")
                    }
                }
                
                // Start real-time listener for existing user
                print("🔊 [App] Starting real-time listener for existing user: \(userId)")
                DataSyncService.shared.startPrivateDictionaryListener(userId: userId)
            } else {
                print("❌ [App] No userId available for initial sync")
            }
        }

        let notificationService = NotificationService.shared
        // Mark app as opened and cancel daily reminder
        notificationService.markAppAsOpened()

        // Only schedule notifications if user has enabled them
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                await notificationService.requestPermission()
                notificationService.scheduleNotificationsForToday()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .fontDesign(.rounded)
                .tint(.accent)
        }
    }
} 

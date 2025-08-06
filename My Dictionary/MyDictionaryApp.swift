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

    @StateObject private var wordsViewModel = WordListViewModel()
    @StateObject private var idiomsViewModel = IdiomListViewModel()
    @StateObject private var quizzesViewModel = QuizzesListViewModel()
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true

    init() {
        FirebaseApp.configure()
        AnalyticsService.shared.logEvent(.appOpened)
        
        // Debug Firebase configuration
        FirebaseDebugService.shared.checkFirebaseConfiguration()
        FirebaseDebugService.shared.checkAuthenticationStatus()
        FirebaseDebugService.shared.testFirestoreWritePermissions()
        
        // Test automatic sync trigger
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("🧪 [App] Testing automatic sync trigger...")
            print("🧪 [App] DataSyncService.shared: \(DataSyncService.shared)")
            NotificationCenter.default.post(name: .NSManagedObjectContextDidSave, object: nil)
        }
        
        // Sync from Firestore on app startup and start real-time listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let userId = AuthenticationService.shared.userId {
                print("🔄 [App] Triggering initial sync from Firestore for userId: \(userId)")
                DataSyncService.shared.syncFirestoreToCoreData(userId: userId) { result in
                    switch result {
                    case .success:
                        print("✅ [App] Initial sync from Firestore completed successfully")
                    case .failure(let error):
                        print("❌ [App] Initial sync from Firestore failed: \(error.localizedDescription)")
                    }
                }
                
                // Start real-time listener for existing user
                print("🔊 [App] Starting real-time listener for existing user: \(userId)")
                DataSyncService.shared.startPrivateDictionaryListener(userId: userId)
                
                // Migrate existing words to include updatedAt field
                DataSyncService.shared.migrateExistingWords()
            } else {
                print("❌ [App] No userId available for initial sync")
            }
        }

        let notificationService = NotificationService.shared
        // Mark app as opened and cancel daily reminder
        notificationService.markAppAsOpened()

        // Only schedule notifications if user has enabled them
        let dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "dailyRemindersEnabled")
        let difficultWordsEnabled = UserDefaults.standard.bool(forKey: "difficultWordsEnabled")
        
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                await notificationService.requestPermission()
                notificationService.scheduleNotificationsForToday()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                wordsViewModel: wordsViewModel,
                idiomsViewModel: idiomsViewModel,
                quizzesViewModel: quizzesViewModel,
                analyticsViewModel: analyticsViewModel,
                settingsViewModel: settingsViewModel
            )
            .fontDesign(.rounded)
            .sheet(isPresented: $isShowingOnboarding) {
                isShowingOnboarding = false
            } content: {
                OnboardingView()
            }
            .tint(.accent)
        }
    }
} 

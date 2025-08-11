//
//  MyDictionaryApp.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📱 [AppDelegate] Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 [AppDelegate] User tapped notification: \(userInfo)")
        
        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "collaborator_invitation":
                if let dictionaryId = userInfo["dictionaryId"] as? String {
                    handleCollaboratorInvitation(dictionaryId: dictionaryId)
                }
            default:
                print("📱 [AppDelegate] Unknown notification type: \(type)")
            }
        }
        
        completionHandler()
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 [AppDelegate] FCM registration token: \(fcmToken ?? "nil")")
        
        if let token = fcmToken {
            // Save FCM token to Firestore
            Task {
                await saveFCMTokenToFirestore(token)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleCollaboratorInvitation(dictionaryId: String) {
        print("📱 [AppDelegate] Handling collaborator invitation for dictionary: \(dictionaryId)")
        
        // Navigate to the shared dictionary
        // This will be implemented when we set up navigation
        DispatchQueue.main.async {
            // TODO: Navigate to shared dictionary
            print("📱 [AppDelegate] Should navigate to shared dictionary: \(dictionaryId)")
        }
    }
    
    private func saveFCMTokenToFirestore(_ token: String) async {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            print("❌ [AppDelegate] No user email available to save FCM token")
            return
        }
        
        do {
            let db = Firestore.firestore()
            try await db.collection("users").document(userEmail).setData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp(),
                "platform": "iOS"
            ], merge: true)
            print("✅ [AppDelegate] FCM token saved for user: \(userEmail)")
        } catch {
            print("❌ [AppDelegate] Failed to save FCM token: \(error)")
        }
    }
}

@main
struct MyDictionaryApp: App {
    
    // Register app delegate for push notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

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

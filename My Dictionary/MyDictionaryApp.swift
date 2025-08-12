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

@main
struct MyDictionaryApp: App {

    #if DEBUG
    @State private var isDebugViewPresented: Bool = false
    #endif

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .fontDesign(.rounded)
                .tint(.accent)
            #if DEBUG
                .onShake {
                    isDebugViewPresented = true
                }
                .sheet(isPresented: $isDebugViewPresented) {
                    DebugView()
                }
            #endif
        }
    }
} 

// MARK: - App Delegate for Push Notifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Register for remote notifications
        application.registerForRemoteNotifications()

        // Clear notification badge when app launches
        clearNotificationBadge()

        // Initialize app services and setup
        setupAppServices()

        return true
    }

    // MARK: - Remote Notification Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 [AppDelegate] APNS device token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // Set the APNS device token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error)")
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
        guard let userId = AuthenticationService.shared.userId,
              let userEmail = AuthenticationService.shared.userEmail else {
            print("❌ [AppDelegate] No user ID or email available to save FCM token")
            return
        }

        do {
            let db = Firestore.firestore()
            
            // Save FCM token with email as document ID (standardized approach)
            try await db.collection("users").document(userEmail).setData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp(),
                "platform": "iOS",
                "userId": userId,
                "email": userEmail,
                "name": AuthenticationService.shared.displayName ?? "Unknown",
                "registrationDate": FieldValue.serverTimestamp(),
                "subscriptionStatus": SubscriptionService.shared.isProUser ? "pro" : "free",
                "subscriptionPlan": SubscriptionService.shared.currentPlan?.rawValue,
                "subscriptionExpiryDate": nil // Will be updated when subscription changes
            ], merge: true)
            
            print("✅ [AppDelegate] FCM token saved for user: \(userEmail)")
        } catch {
            print("❌ [AppDelegate] Failed to save FCM token: \(error)")
        }
    }

    // MARK: - Simulator Testing

    #if DEBUG
    func testLocalNotification() {
        print("🧪 [AppDelegate] Testing local notification on simulator")

        let content = UNMutableNotificationContent()
        content.title = "Test Dictionary Invitation"
        content.body = "Someone added you to 'Test Dictionary'"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "collaborator_invitation",
            "dictionaryId": "test-dictionary-id",
            "inviterName": "Test User",
            "dictionaryName": "Test Dictionary"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [AppDelegate] Failed to schedule test notification: \(error)")
            } else {
                print("✅ [AppDelegate] Test notification scheduled successfully")
            }
        }
    }
    #endif

    // MARK: - App Lifecycle

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear notification badge when app becomes active
        clearNotificationBadge()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Clear notification badge when app enters foreground
        clearNotificationBadge()
    }

        // MARK: - Notification Badge Management
    
    private func clearNotificationBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            print("🧹 [AppDelegate] Cleared notification badge")
        }
    }
    
    // MARK: - App Services Setup
    
    private func setupAppServices() {
        print("🔧 [AppDelegate] Setting up app services...")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Firestore for offline persistence
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
        
        // Log analytics event
        AnalyticsService.shared.logEvent(.appOpened)
        
        // Debug Firebase configuration
        FirebaseDebugService.shared.checkFirebaseConfiguration()
        FirebaseDebugService.shared.checkAuthenticationStatus()
        
        // Setup notifications
        setupNotifications()
        
        // Setup data sync
        setupDataSync()
        
        print("✅ [AppDelegate] App services setup completed")
    }
    
    private func setupNotifications() {
        let notificationService = NotificationService.shared
        
        // Mark app as opened and cancel daily reminder
        notificationService.markAppAsOpened()
        
        // Check if user has enabled notifications
        let dailyRemindersEnabled = UserDefaults.standard.bool(forKey: UDKeys.dailyRemindersEnabled)
        let difficultWordsEnabled = UserDefaults.standard.bool(forKey: UDKeys.difficultWordsEnabled)
        
        // Only schedule notifications if user has enabled them
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                await notificationService.requestPermission()
                notificationService.scheduleNotificationsForToday()
            }
        }
    }
    
    private func setupDataSync() {
        // Sync from Firestore on app startup and start real-time listener
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let userId = AuthenticationService.shared.userId {
                print("🔄 [AppDelegate] Triggering initial sync from Firestore for userId: \(userId)")
                Task {
                    do {
                        try await DataSyncService.shared.syncFirestoreToCoreData(userId: userId)
                        print("✅ [AppDelegate] Initial sync from Firestore completed successfully")
                    } catch {
                        print("❌ [AppDelegate] Initial sync from Firestore failed: \(error.localizedDescription)")
                    }
                }
                
                // Start real-time listener for existing user
                print("🔊 [AppDelegate] Starting real-time listener for existing user: \(userId)")
                DataSyncService.shared.startPrivateDictionaryListener(userId: userId)
            } else {
                print("❌ [AppDelegate] No userId available for initial sync")
            }
        }
    }
}

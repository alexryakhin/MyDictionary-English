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
                // DO NOT TRANSLATE DEBUG
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

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Set up push notification delegates
        UNUserNotificationCenter.current().delegate = self

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
        // Set the APNS device token for Firebase Messaging
        MessagingService.shared.setAPNSToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping VoidHandler) {
        let userInfo = response.notification.request.content.userInfo

        // Handle different notification types
        if let type = userInfo["type"] as? String {
            switch type {
            case "collaborator_invitation":
                if let dictionaryId = userInfo["dictionaryId"] as? String {
                    handleCollaboratorInvitation(dictionaryId: dictionaryId)
                }
            default:
                break
            }
        }

        completionHandler()
    }

    // MARK: - Private Methods

    private func handleCollaboratorInvitation(dictionaryId: String) {
        // Navigate to the shared dictionary
        DispatchQueue.main.async {
            if let sharedDictionary = DictionaryService.shared.sharedDictionaries.first(where: { $0.id == dictionaryId }) {
                NavigationManager.shared.navigationPath.append(NavigationDestination.sharedDictionaryWords(sharedDictionary))
            }
        }
    }



    // MARK: - Simulator Testing

    // DO NOT TRANSLATE DEBUG
    #if DEBUG
    func testLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = Loc.Notifications.testDictionaryInvitation.localized
        content.body = Loc.Notifications.testDictionaryInvitationBody.localized
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

        UNUserNotificationCenter.current().add(request) { _ in }
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
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Unregister device token when app terminates
        Task {
            await MessagingService.shared.unregisterCurrentDevice()
        }
    }

    // MARK: - Notification Badge Management

    private func clearNotificationBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    // MARK: - App Services Setup

    private func setupAppServices() {
        // Configure Firebase FIRST
        FirebaseApp.configure()

        // Configure Firestore for offline persistence
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings

        // Initialize MessagingService AFTER Firebase is configured
        _ = MessagingService.shared

        // Log analytics event
        AnalyticsService.shared.logEvent(.appOpened)

        // DO NOT TRANSLATE DEBUG
        #if DEBUG
        // Debug Firebase configuration
        FirebaseDebugService.shared.checkFirebaseConfiguration()
        FirebaseDebugService.shared.checkAuthenticationStatus()
        #endif

        // Setup notifications
        setupNotifications()
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
}

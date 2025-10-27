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
    @StateObject private var migrationService = DataMigrationService.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    if migrationService.needsMigration && !migrationService.isInProgress {
                        try? await migrationService.performMigration()
                    }
                }
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
        print("🔔 [AppDelegate] Notification tapped with userInfo: \(userInfo)")

        // Handle different notification types
        if let type = userInfo["type"] as? String {
            print("🔔 [AppDelegate] Notification type: \(type)")
            switch type {
            case "collaborator_invitation":
                if let dictionaryId = userInfo["dictionaryId"] as? String {
                    print("🔔 [AppDelegate] Handling collaborator invitation for dictionary: \(dictionaryId)")
                    handleCollaboratorInvitation(dictionaryId: dictionaryId)
                }
            case "word_study":
                if let wordId = userInfo["wordId"] as? String {
                    print("🔔 [AppDelegate] Handling word study notification for word ID: \(wordId)")
                    handleWordStudyNotification(wordId: wordId)
                } else {
                    print("🔔 [AppDelegate] Word study notification missing wordId")
                }
            default:
                print("🔔 [AppDelegate] Unknown notification type: \(type)")
                break
            }
        } else {
            print("🔔 [AppDelegate] Notification missing type in userInfo")
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
    
    private func handleWordStudyNotification(wordId: String) {
        print("🔔 [AppDelegate] Looking for word with ID: \(wordId)")
        // Find the word by ID and navigate to word details
        DispatchQueue.main.async {
            if let word = self.findWord(by: wordId) {
                print("🔔 [AppDelegate] Found word: \(word.wordItself ?? "Unknown"), navigating to details")
                NavigationManager.shared.navigationPath.append(NavigationDestination.wordDetails(word))
            } else {
                print("🔔 [AppDelegate] Word not found with ID: \(wordId)")
            }
        }
    }
    
    private func findWord(by id: String) -> CDWord? {
        print("🔔 [AppDelegate] Converting string ID to UUID: \(id)")
        guard let uuid = UUID(uuidString: id) else { 
            print("🔔 [AppDelegate] Failed to convert string to UUID: \(id)")
            return nil 
        }
        
        let request = CDWord.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let words = try CoreDataService.shared.context.fetch(request)
            print("🔔 [AppDelegate] Found \(words.count) words with ID \(id)")
            return words.first
        } catch {
            print("🔔 [AppDelegate] Error finding word with ID \(id): \(error)")
            return nil
        }
    }

    // MARK: - Simulator Testing

    // DO NOT TRANSLATE DEBUG
    #if DEBUG
    func testLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = Loc.Notifications.testDictionaryInvitation
        content.body = Loc.Notifications.testDictionaryInvitationBody
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
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule notifications when app goes to background (check for hard words)
        NotificationService.shared.scheduleNotificationsOnAppExit()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Schedule notifications when app terminates (check for hard words)
        NotificationService.shared.scheduleNotificationsOnAppExit()
        
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
        
        // Disable Analytics in DEBUG mode
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
        print("🔧 [DEBUG] Firebase Analytics disabled")
        #endif

        // Configure Firestore for offline persistence
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings

        // Initialize MessagingService AFTER Firebase is configured
        _ = MessagingService.shared

        // Initialize FeatureToggleService AFTER Firebase is configured
        _ = FeatureToggleService.shared

        // Initialize RemoteConfigService AFTER Firebase is configured
        Task {
            await RemoteConfigService.shared.fetchConfiguration()
            
            // Check and generate AI paywall content if needed (after services are ready)
            await PaywallContentService.shared.checkAndGenerateIfNeeded()
        }

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
        // Notifications are now scheduled when app goes to background/quits
        // No need to schedule on app launch
    }
}

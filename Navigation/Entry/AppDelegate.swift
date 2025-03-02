//
//  AppDelegate.swift
//  MyDictionary
//
//  Created by Aleksandr Riakhin on 9/29/24.
//

import Foundation
import UIKit
import Firebase
//import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate/*, MessagingDelegate*/ {

    // Called when the app finishes launching
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        setupLogger()
#if DEBUG
        info("Home directory:", NSHomeDirectory(), "\n")
#endif
        DIContainer.shared.assemble(assembly: ServiceAssembly())
        // Initialize Firebase
         FirebaseApp.configure()

        // Set up Firebase Cloud Messaging delegate
        // Messaging.messaging().delegate = self

//        requestNotificationAuthorization(application: application)

        return true
    }

    /// Request authorization to show notifications
    func requestNotificationAuthorization(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
                if granted {
                    info("Notification permission granted")
                    application.registerForRemoteNotifications()
                } else {
                    warn("Notification permission denied")
                }
            } catch {
                fault("Error requesting notifications permission: \(error.localizedDescription)")
            }
        }
    }

    // Called when the device receives a push notification token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Messaging.messaging().apnsToken = deviceToken
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        info("Successfully registered for notifications! Token: \(tokenString)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        fault("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Called when Firebase Messaging refreshes the token
    // func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // print("Firebase registration token: \(String(describing: fcmToken))")
        // Here, you would typically send the token to your server for later use
    // }

    // Handle notification while app is in the foreground
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound]) // Present banner and play sound while app is in the foreground
    }

    // Handle tap on notification while app is in the background or closed
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap here (e.g., navigate to a specific view)
        info("User tapped notification")
        completionHandler()
    }

    func setupLogger() {
        logger.moduleName = "MY_DICTIONARY"

        let message: String
#if DEBUG
        logger.minLogLevel = .debug
        message = "Logger level: SHOW ALL EVENTS"
#else
        message = "SWIFT_ACTIVE_COMPILATION_CONDITIONS is not set"
#endif
        logger.log(message, eventLevel: .important)
    }
}

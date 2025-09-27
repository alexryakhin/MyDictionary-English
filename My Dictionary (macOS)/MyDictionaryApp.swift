//
//  MyDictionaryApp.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/29/25.
//

import SwiftUI
import Firebase
import Combine
import UserNotifications
import AppKit
import FirebaseFirestore

@main
struct MyDictionaryApp: App {

    @Environment(\.openWindow) private var openWindow
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Configure Firebase FIRST
        FirebaseApp.configure()
    }

    var body: some Scene {
        Window(Loc.Onboarding.myDictionary, id: WindowID.main) {
            SideBarView()
                .migrationAware()
                .fontDesign(.rounded)
                .tint(.accent)
                .frame(width: 1000, height: 640)
                .background(Color.systemGroupedBackground)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.about)
                } label: {
                    Text(Loc.Settings.aboutMyDictionary)
                }
            }
            
            // DO NOT TRANSLATE DEBUG
            #if DEBUG
            CommandGroup(after: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.debug)
                } label: {
                    Text("Debug panel")
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
        }
        .defaultSize(width: 900, height: 500)

        Window(Loc.Settings.aboutMyDictionary, id: WindowID.about) {
            AboutAppView()
        }
        .defaultSize(width: 600, height: 600)

        Settings {
            SettingsView()
        }
        .defaultSize(width: 500, height: 650)

        // DO NOT TRANSLATE DEBUG
        #if DEBUG
        Window("Debug panel", id: WindowID.debug) {
            DebugView()
        }
        .defaultSize(width: 600, height: 800)
        #endif
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize app services and setup
        setupAppServices()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Unregister device token when app terminates
        Task {
            await MessagingService.shared.unregisterCurrentDevice()
        }
    }
    
    func applicationDidBecomeActive(_ aNotification: Notification) {
        // Mark app as opened and cancel daily reminder
        NotificationService.shared.markAppAsOpened()
    }
    
    // MARK: - App Services Setup
    
    private func setupAppServices() {
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
        let dailyRemindersEnabled = UDService.dailyRemindersEnabled
        let difficultWordsEnabled = UDService.difficultWordsEnabled

        // Only schedule notifications if user has enabled them
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                await notificationService.requestPermission()
                notificationService.scheduleNotificationsForToday()
            }
        }
    }
}

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

@main
struct MyDictionaryApp: App {

    @Environment(\.openWindow) private var openWindow
    private var messagingService: MessagingService?

    init() {
        // Configure Firebase FIRST
        FirebaseApp.configure()
        
        // Initialize MessagingService AFTER Firebase is configured
        messagingService = MessagingService.shared
    }

    var body: some Scene {
        Window(Loc.MacOS.myDictionary.localized, id: WindowID.main) {
            SideBarView()
                .font(.system(.body, design: .rounded))
                .frame(width: 900, height: 550)
                .background(Color.systemGroupedBackground)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.about)
                } label: {
                    Text(Loc.App.aboutMyDictionary.localized)
                }
            }
            
            // DO NOT TRANSLATE DEBUG
            #if DEBUG
            CommandGroup(after: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.debug)
                } label: {
                    Text(Loc.MacOS.debugPanel.localized)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
        }
        .defaultSize(width: 900, height: 500)

        Window(Loc.MacOS.aboutMyDictionary.localized, id: WindowID.about) {
            AboutAppView()
        }
        .defaultSize(width: 600, height: 600)

        // DO NOT TRANSLATE DEBUG
        #if DEBUG
        Window(Loc.MacOS.debugPanel.localized, id: WindowID.debug) {
            DebugView()
        }
        .defaultSize(width: 600, height: 800)
        #endif

        Settings {
            SettingsView()
        }
        .defaultSize(width: 500, height: 650)
    }
}

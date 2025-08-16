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

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        Window("My Dictionary", id: WindowID.main) {
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
                    Text("About My Dictionary")
                }
            }
            
            #if DEBUG
            CommandGroup(after: CommandGroupPlacement.appInfo) {
                Button {
                    openWindow(id: WindowID.debug)
                } label: {
                    Text("Debug Panel")
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            #endif
        }
        .defaultSize(width: 900, height: 500)

        Window("About My Dictionary", id: WindowID.about) {
            AboutAppView()
        }
        .defaultSize(width: 600, height: 600)

        #if DEBUG
        Window("Debug Panel", id: WindowID.debug) {
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

//
//  MyDictionaryApp.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/29/25.
//

import SwiftUI
import Firebase
import UserInterface__macOS_

@main
struct MyDictionaryApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .font(.system(.body, design: .rounded))
        }
        .windowStyle(TitleBarWindowStyle())
        .windowToolbarStyle(.unifiedCompact)

        Settings {
            DictionarySettings()
        }
    }
}

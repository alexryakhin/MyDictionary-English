//
//  AppDelegate.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import SwiftUI
import Firebase

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure() // Initialize Firebase
        AnalyticsService.shared.logEvent(.appOpened)
        return true
    }
}

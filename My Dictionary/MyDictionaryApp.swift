//
//  MyDictionaryApp.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import Firebase

@main
struct MyDictionaryApp: App {

    @StateObject private var wordsViewModel = WordsListViewModel()
    @StateObject private var idiomsViewModel = IdiomsListViewModel()
    @StateObject private var quizzesViewModel = QuizzesListViewModel()
    @StateObject private var analyticsViewModel = AnalyticsViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true

    init() {
        FirebaseApp.configure()
        AnalyticsService.shared.logEvent(.appOpened)
        
        // Mark app as opened and cancel daily reminder
        ServiceManager.shared.notificationService.markAppAsOpened()
        
        // Only schedule notifications if user has enabled them
        let dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "dailyRemindersEnabled")
        let difficultWordsEnabled = UserDefaults.standard.bool(forKey: "difficultWordsEnabled")
        
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                await ServiceManager.shared.notificationService.requestPermission()
                ServiceManager.shared.notificationService.scheduleNotificationsForToday()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                wordsViewModel: wordsViewModel,
                idiomsViewModel: idiomsViewModel,
                quizzesViewModel: quizzesViewModel,
                analyticsViewModel: analyticsViewModel,
                settingsViewModel: settingsViewModel
            )
            .fontDesign(.rounded)
            .sheet(isPresented: $isShowingOnboarding) {
                isShowingOnboarding = false
            } content: {
                OnboardingView()
            }
            .tint(.accent)
        }
    }
} 

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
    @StateObject private var moreViewModel = MoreViewModel()

    @AppStorage(UDKeys.isShowingOnboarding) var isShowingOnboarding: Bool = true

    init() {
        FirebaseApp.configure()
        AnalyticsService.shared.logEvent(.appOpened)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(
                wordsViewModel: wordsViewModel,
                idiomsViewModel: idiomsViewModel,
                quizzesViewModel: quizzesViewModel,
                analyticsViewModel: analyticsViewModel,
                moreViewModel: moreViewModel
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

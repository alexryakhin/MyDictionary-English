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
    @StateObject private var idiomsViewModel = IdiomsListViewModel(
        idiomsProvider: ServiceManager.shared.idiomsProvider
    )
    @StateObject private var quizzesViewModel = QuizzesListViewModel(
        wordsProvider: ServiceManager.shared.wordsProvider
    )
    @StateObject private var moreViewModel = MoreViewModel(
        wordsProvider: ServiceManager.shared.wordsProvider,
        csvManager: ServiceManager.shared.csvManager
    )

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
                moreViewModel: moreViewModel
            )
        }
    }
} 

//
//  AppInitializationManager.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI
import Combine
import AppKit

@MainActor
final class AppInitializationManager: ObservableObject {

    static let shared = AppInitializationManager()

    @Published var initializationState: AppInitializationState = .loading
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        startInitialization()
    }
    
    private func setupBindings() {
        // Listen for authentication completion
        NotificationCenter.default.publisher(for: .authenticationCompleted)
            .sink { [weak self] _ in
                self?.handleAuthenticationCompleted()
            }
            .store(in: &cancellables)
        
        // Listen for onboarding completion
        NotificationCenter.default.publisher(for: .onboardingCompleted)
            .sink { [weak self] _ in
                self?.handleOnboardingCompleted()
            }
            .store(in: &cancellables)
    }
    
    private func startInitialization() {
        Task {
            await performInitialization()
        }
    }
    
    private func performInitialization() async {
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if !hasCompletedOnboarding {
            await MainActor.run {
                initializationState = .onboarding
                isLoading = false
            }
            return
        }
        
        // Check authentication status
        let isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        
        if !isAuthenticated {
            await MainActor.run {
                initializationState = .authentication
                isLoading = false
            }
            return
        }
        
        // User is authenticated, proceed to main app
        await MainActor.run {
            initializationState = .mainApp
            isLoading = false
        }
        
        // Setup notifications
        setupNotifications()
        
        // Perform data synchronization
        await performDataSync()
    }
    
    private func setupNotifications() {
        let notificationService = NotificationService.shared

        // Mark app as opened and cancel daily reminder
        notificationService.markAppAsOpened()

        // Check if user has enabled notifications
        let dailyRemindersEnabled = UserDefaults.standard.bool(forKey: UDKeys.dailyRemindersEnabled)
        let difficultWordsEnabled = UserDefaults.standard.bool(forKey: UDKeys.difficultWordsEnabled)

        // Only schedule notifications if user has enabled them
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                await notificationService.requestPermission()
                notificationService.scheduleNotificationsForToday()
            }
        }
    }
    
    private func performDataSync() async {
        // Manual sync mode - no automatic sync on app startup
        print("ℹ️ [App] Manual sync mode enabled - no automatic sync on startup")
    }
    
    private func handleAuthenticationCompleted() {
        Task {
            await performDataSync()
            await MainActor.run {
                initializationState = .mainApp
            }
        }
    }
    
    private func handleOnboardingCompleted() {
        Task {
            await MainActor.run {
                initializationState = .mainApp
            }
        }
    }
}

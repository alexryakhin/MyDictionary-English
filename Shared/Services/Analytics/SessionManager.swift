//
//  SessionManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/10/25.
//

import Foundation
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published var showCoffeeBanner = false

    private var currentSessionDuration: TimeInterval = 0
    private var isSessionActive = false
    private var sessionTimer: Timer?
    private var sessionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startSession()
        setupAppLifecycleObservers()
    }
    
    // MARK: - Session Management
    
    func startSession() {
        guard !isSessionActive else { return }
        
        sessionStartTime = Date()
        isSessionActive = true
        
        // Save session start time
        UDService.sessionStartTime = sessionStartTime
        
        // Start timer to track session duration
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }
    }
    
    func pauseSession() {
        guard isSessionActive else { return }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false
    }
    
    func resumeSession() {
        guard !isSessionActive else { return }
        
        // Restore session start time if it exists
        if let savedStartTime = UDService.sessionStartTime {
            sessionStartTime = savedStartTime
        } else {
            sessionStartTime = Date()
        }
        
        isSessionActive = true
        
        // Restart timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }
    }
    
    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false
        sessionStartTime = nil
        currentSessionDuration = 0
        
        // Clear saved session start time
        UDService.sessionStartTime = nil
    }

    private func updateSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        
        currentSessionDuration = Date().timeIntervalSince(startTime)
        
        // Check for coffee banner trigger (20 minutes = 1200 seconds)
        if currentSessionDuration >= 1200 && shouldShowCoffeeBanner() {
            DispatchQueue.main.async {
                self.showCoffeeBanner = true
            }
        }
    }
    
    // MARK: - Coffee Banner Logic
    
    private func shouldShowCoffeeBanner() -> Bool {
        // Don't show if user hasn't completed onboarding
        if !UDService.hasCompletedOnboarding {
            return false
        }
        
        // Don't show if already shown this week
        if UDService.hasShownCoffeeThisWeek {
            return false
        }
        
        // Don't show too frequently (minimum 14 days between requests)
        if let lastCoffeeDate = UDService.lastCoffeeRequestDate {
            let daysSinceLastCoffee = Calendar.current.dateComponents([.day], from: lastCoffeeDate, to: Date()).day ?? 0
            guard daysSinceLastCoffee >= 14 else { return false }
        }
        
        // Don't show too many times (maximum 3 times total)
        let coffeeRequestCount = UDService.coffeeRequestCount
        guard coffeeRequestCount < 3 else { return false }
        
        return true
    }
    
    func markCoffeeBannerShown() {
        UDService.lastCoffeeRequestDate = Date.now
        UDService.hasShownCoffeeThisWeek = true
        
        let currentCount = UDService.coffeeRequestCount
        UDService.coffeeRequestCount = currentCount + 1
        
        showCoffeeBanner = false
    }
    
    func markCoffeeBannerDismissed() {
        UDService.lastCoffeeRequestDate = Date.now

        let currentCount = UDService.coffeeRequestCount
        UDService.coffeeRequestCount = currentCount + 1
        
        showCoffeeBanner = false
    }
    
    // MARK: - Weekly Reset
    
    func resetWeeklyFlags() {
        UDService.hasShownCoffeeThisWeek = false
    }
    
    // MARK: - App Lifecycle Observers

#if os(iOS)
    private func setupAppLifecycleObservers() {
        // Observe when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.resumeSession()
                self?.checkAndResetWeeklyFlags()
            }
            .store(in: &cancellables)

        // Observe when app goes to background
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseSession()
            }
            .store(in: &cancellables)
    }
#elseif os(macOS)
    private func setupAppLifecycleObservers() {
        // Observe when app becomes active
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.resumeSession()
                self?.checkAndResetWeeklyFlags()
            }
            .store(in: &cancellables)

        // Observe when app goes to background
        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseSession()
            }
            .store(in: &cancellables)
    }
#endif

    private func checkAndResetWeeklyFlags() {
        // Check if we need to reset weekly flags (every Monday)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Monday is weekday 2 in Calendar
        if weekday == 2 {
            resetWeeklyFlags()
        }
    }
}



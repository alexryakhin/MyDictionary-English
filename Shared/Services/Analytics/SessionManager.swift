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
    
    @Published private(set) var currentSessionDuration: TimeInterval = 0
    @Published private(set) var isSessionActive = false
    @Published var showCoffeeBanner = false

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
        UserDefaults.standard.set(sessionStartTime?.timeIntervalSince1970, forKey: UDKeys.sessionStartTime)
        
        // Start timer to track session duration
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }
        
        print("🔹 [SessionManager] Session started")
    }
    
    func pauseSession() {
        guard isSessionActive else { return }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false
        
        print("🔹 [SessionManager] Session paused. Duration: \(currentSessionDuration) seconds")
    }
    
    func resumeSession() {
        guard !isSessionActive else { return }
        
        // Restore session start time if it exists
        if let savedStartTime = UserDefaults.standard.object(forKey: UDKeys.sessionStartTime) as? TimeInterval {
            sessionStartTime = Date(timeIntervalSince1970: savedStartTime)
        } else {
            sessionStartTime = Date()
        }
        
        isSessionActive = true
        
        // Restart timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionDuration()
        }
        
        print("🔹 [SessionManager] Session resumed")
    }
    
    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        isSessionActive = false
        sessionStartTime = nil
        currentSessionDuration = 0
        
        // Clear saved session start time
        UserDefaults.standard.removeObject(forKey: UDKeys.sessionStartTime)
        
        print("🔹 [SessionManager] Session ended")
    }
    
    private func updateSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        
        currentSessionDuration = Date().timeIntervalSince(startTime)
        
        // Check for coffee banner trigger (10 minutes = 600 seconds)
        if currentSessionDuration >= 600 && shouldShowCoffeeBanner() {
            DispatchQueue.main.async {
                self.showCoffeeBanner = true
            }
        }
    }
    
    // MARK: - Coffee Banner Logic
    
    private func shouldShowCoffeeBanner() -> Bool {
        // Don't show if already shown this week
        if UserDefaults.standard.bool(forKey: UDKeys.hasShownCoffeeThisWeek) {
            return false
        }
        
        // Don't show too frequently (minimum 14 days between requests)
        let lastCoffeeDate = UserDefaults.standard.object(forKey: UDKeys.lastCoffeeRequestDate) as? Date ?? Date.distantPast
        let daysSinceLastCoffee = Calendar.current.dateComponents([.day], from: lastCoffeeDate, to: Date()).day ?? 0
        
        guard daysSinceLastCoffee >= 14 else { return false }
        
        // Don't show too many times (maximum 3 times total)
        let coffeeRequestCount = UserDefaults.standard.integer(forKey: UDKeys.coffeeRequestCount)
        guard coffeeRequestCount < 3 else { return false }
        
        return true
    }
    
    func markCoffeeBannerShown() {
        UserDefaults.standard.set(Date(), forKey: UDKeys.lastCoffeeRequestDate)
        UserDefaults.standard.set(true, forKey: UDKeys.hasShownCoffeeThisWeek)
        
        let currentCount = UserDefaults.standard.integer(forKey: UDKeys.coffeeRequestCount)
        UserDefaults.standard.set(currentCount + 1, forKey: UDKeys.coffeeRequestCount)
        
        showCoffeeBanner = false
        print("🔹 [SessionManager] Coffee banner marked as shown")
    }
    
    func markCoffeeBannerDismissed() {
        UserDefaults.standard.set(Date(), forKey: UDKeys.lastCoffeeRequestDate)
        
        let currentCount = UserDefaults.standard.integer(forKey: UDKeys.coffeeRequestCount)
        UserDefaults.standard.set(currentCount + 1, forKey: UDKeys.coffeeRequestCount)
        
        showCoffeeBanner = false
        print("🔹 [SessionManager] Coffee banner dismissed")
    }
    
    // MARK: - Weekly Reset
    
    func resetWeeklyFlags() {
        UserDefaults.standard.set(false, forKey: UDKeys.hasShownCoffeeThisWeek)
        print("🔹 [SessionManager] Weekly flags reset")
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



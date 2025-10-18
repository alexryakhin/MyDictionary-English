//
//  NotificationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import UserNotifications
import CoreData

final class NotificationService {

    static let shared = NotificationService()

    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private let tagService = TagService.shared

    private init() {}
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = Loc.Notifications.timeToPractice
        content.body = Loc.Notifications.practiceVocabularyToday
        content.sound = .default
        
        // Schedule using user's preferred time from UserDefaults
        let userTime = UDService.dailyRemindersTime
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: userTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }
    
    func scheduleDifficultWordsReminder() {
        let content = UNMutableNotificationContent()
        content.title = Loc.Notifications.practiceDifficultWords
        content.body = Loc.Notifications.difficultWordsChallenge
        content.sound = .default
        
        // Schedule using user's preferred time from UserDefaults
        let userTime = UDService.difficultWordsTime
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: userTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "difficult-words-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling difficult words reminder: \(error)")
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-reminder"])
    }
    
    func cancelDifficultWordsReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["difficult-words-reminder"])
    }
    
    /// Schedules notifications based on user preferences
    /// - Daily reminders: Scheduled daily at set time if enabled (no logic about app opening)
    /// - Difficult words: Scheduled daily if user has hard words
    func scheduleNotifications() async {
        // Check user preferences first
        let dailyRemindersEnabled = UDService.dailyRemindersEnabled
        let difficultWordsEnabled = UDService.difficultWordsEnabled
        
        // Only proceed if any notifications are enabled
        guard dailyRemindersEnabled || difficultWordsEnabled else { return }
        
        // Check permission status
        let status = await UNUserNotificationCenter.current().notificationSettings()
        guard status.authorizationStatus == .authorized else { return }
        
        // Cancel all existing notifications
        cancelAllNotifications()
        
        // Schedule daily reminder if enabled (always schedule, regardless of app usage)
        if dailyRemindersEnabled {
            scheduleDailyReminder()
        }
        
        // Schedule difficult words reminder if enabled and user has hard words
        if difficultWordsEnabled {
            let wordProgress = quizAnalyticsService.getWordProgress()
            let difficultWords = wordProgress.filter { $0.masteryLevel == "needReview" }
            
            if !difficultWords.isEmpty {
                scheduleDifficultWordsReminder()
            } else {
                // Cancel difficult words notification if no hard words
                cancelDifficultWordsReminder()
            }
        }
    }
    
    /// Called when app goes to background or quits - reschedules notifications
    func scheduleNotificationsOnAppExit() {
        Task {
            await scheduleNotifications()
        }
    }
    
    /// Called when user toggles notification settings or changes time
    func scheduleNotificationsForSettings() {
        Task {
            let dailyRemindersEnabled = UDService.dailyRemindersEnabled
            let difficultWordsEnabled = UDService.difficultWordsEnabled
            
            guard dailyRemindersEnabled || difficultWordsEnabled else {
                cancelAllNotifications()
                return
            }
            
            await scheduleNotifications()
        }
    }
} 

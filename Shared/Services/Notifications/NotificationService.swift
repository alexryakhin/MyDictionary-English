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
        content.title = "Time to Practice! 📚"
        content.body = "Don't forget to practice your vocabulary today."
        content.sound = .default
        
        // Schedule for 8:00 PM today (only if user hasn't opened app today)
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }
    
    func scheduleDifficultWordsReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Practice Your Difficult Words 📚"
        content.body = "You have words that need more practice. Ready for a challenge?"
        content.sound = .default
        
        // Schedule for 4:00 PM today
        var dateComponents = DateComponents()
        dateComponents.hour = 16 // 4 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
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
    
    func checkAndScheduleNotifications() {
        Task {
            let hasPermission = await requestPermission()
            guard hasPermission else { return }
            
            // Check user preferences
            let dailyRemindersEnabled = UserDefaults.standard.bool(forKey: "dailyRemindersEnabled")
            let difficultWordsEnabled = UserDefaults.standard.bool(forKey: "difficultWordsEnabled")
            
            // Only schedule daily reminder if enabled and user hasn't opened app today
            if dailyRemindersEnabled {
                let today = Calendar.current.startOfDay(for: Date())
                let lastOpened = UserDefaults.standard.object(forKey: "lastAppOpenDate") as? Date ?? Date.distantPast
                
                if Calendar.current.startOfDay(for: lastOpened) < today {
                    scheduleDailyReminder()
                }
            }
            
            // Check for difficult words and schedule 4 PM reminder if enabled
            if difficultWordsEnabled {
                let wordProgress = quizAnalyticsService.getWordProgress()
                let difficultWords = wordProgress.filter { $0.masteryLevel == "needReview" }
                
                if !difficultWords.isEmpty {
                    scheduleDifficultWordsReminder()
                }
            }
        }
    }
    
    func scheduleNotificationsForToday() {
        Task {
            let hasPermission = await requestPermission()
            guard hasPermission else { return }
            
            // Cancel existing notifications
            cancelAllNotifications()
            
            // Schedule new notifications
            checkAndScheduleNotifications()
        }
    }
    
    func markAppAsOpened() {
        UserDefaults.standard.set(Date(), forKey: "lastAppOpenDate")
        cancelDailyReminder()
    }
} 

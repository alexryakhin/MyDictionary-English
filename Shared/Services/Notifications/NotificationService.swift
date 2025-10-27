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
    
    func scheduleWordStudyNotifications() {
        // Check if user has a UserProfile with study time preference
        guard let userProfile = CoreDataService.shared.fetchUserProfile(),
              let studyTimeString = userProfile.preferredStudyTime,
              let studyTime = StudyTime(rawValue: studyTimeString) else {
            print("No user profile or study time found for word study notifications")
            return
        }
        
        // Reset daily tracking if needed
        resetDailyTracking()
        
        // Get study time range
        let studyTimeRange = getStudyTimeRange(from: studyTime)
        
        // Generate 5-10 random times within the study period
        let notificationCount = Int.random(in: 5...10)
        let randomTimes = generateRandomTimes(in: studyTimeRange, count: notificationCount)
        
        // Get words for notifications
        let words = getRandomWordsForNotifications(count: notificationCount)
        
        // Schedule notifications
        for (index, time) in randomTimes.enumerated() {
            guard index < words.count else { break }
            
            let word = words[index]
            let content = UNMutableNotificationContent()
            content.title = Loc.Notifications.wordStudyTitle(word.wordItself ?? "")
            
            // Get definition and example
            let definition = word.primaryDefinition ?? ""
            let examples = word.primaryMeaning?.examplesDecoded ?? []
            let example = examples.first ?? ""
            
            // Only include example if it exists
            if !example.isEmpty {
                content.body = Loc.Notifications.wordStudyBody(definition, example)
            } else {
                content.body = definition
            }
            content.sound = .default
            
            // Create trigger for specific time today
            let calendar = Calendar.current
            let now = Date()
            let targetDate = calendar.date(bySettingHour: time, minute: Int.random(in: 0...59), second: 0, of: now) ?? now
            
            // If the time has already passed today, schedule for tomorrow
            let finalDate = targetDate > now ? targetDate : calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
            
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Add word ID to notification data for deep linking
            content.userInfo = [
                "type": "word_study",
                "wordId": word.id?.uuidString ?? ""
            ]
            
            let request = UNNotificationRequest(
                identifier: "word-study-\(index)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling word study notification \(index): \(error)")
                } else {
                    // Mark word as shown today
                    self.markWordAsShown(wordId: word.id?.uuidString ?? "")
                }
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
    
    func cancelWordStudyNotifications() {
        let identifiers = (0..<10).map { "word-study-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /// Schedules notifications based on user preferences
    /// - Daily reminders: Scheduled daily at set time if enabled (no logic about app opening)
    /// - Difficult words: Scheduled daily if user has hard words
    /// - Word study: Scheduled during user's preferred study time with random vocabulary
    func scheduleNotifications() async {
        // Check user preferences first
        let dailyRemindersEnabled = UDService.dailyRemindersEnabled
        let difficultWordsEnabled = UDService.difficultWordsEnabled
        let wordStudyEnabled = UDService.wordStudyNotificationsEnabled
        
        // Only proceed if any notifications are enabled
        guard dailyRemindersEnabled || difficultWordsEnabled || wordStudyEnabled else { return }
        
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
        
        // Schedule word study notifications if enabled
        if wordStudyEnabled {
            scheduleWordStudyNotifications()
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
            let wordStudyEnabled = UDService.wordStudyNotificationsEnabled
            
            guard dailyRemindersEnabled || difficultWordsEnabled || wordStudyEnabled else {
                cancelAllNotifications()
                return
            }
            
            await scheduleNotifications()
        }
    }
    
    // MARK: - Word Study Notification Helpers
    
    private func getStudyTimeRange(from studyTime: StudyTime) -> ClosedRange<Int> {
        switch studyTime {
        case .morning:
            return 6...12
        case .afternoon:
            return 12...18
        case .evening:
            return 18...22
        case .flexible:
            return 6...22
        }
    }
    
    private func generateRandomTimes(in range: ClosedRange<Int>, count: Int) -> [Int] {
        var times: [Int] = []
        for _ in 0..<count {
            let randomHour = Int.random(in: range)
            times.append(randomHour)
        }
        return times.sorted()
    }
    
    private func getRandomWordsForNotifications(count: Int) -> [CDWord] {
        let context = CoreDataService.shared.context
        
        // First, try to get difficult words
        let difficultWordsRequest = CDWordProgress.fetchRequest()
        difficultWordsRequest.predicate = NSPredicate(format: "masteryLevel == %@", "needReview")
        let difficultWordProgress = (try? context.fetch(difficultWordsRequest)) ?? []
        
        var availableWords: [CDWord] = []
        
        // Get words from difficult word progress
        for progress in difficultWordProgress where progress.wordId != nil {
            let wordRequest = CDWord.fetchRequest()
            wordRequest.predicate = NSPredicate(format: "id == %@", progress.wordId!)
            if let word = try? context.fetch(wordRequest).first,
               !hasShownWordToday(wordId: word.id?.uuidString ?? "") {
                availableWords.append(word)
            }
        }
        
        // If we don't have enough difficult words, supplement with random words
        if availableWords.count < count {
            let allWordsRequest = CDWord.fetchRequest()
            let allWords = (try? context.fetch(allWordsRequest)) ?? []
            let filteredWords = allWords.filter { word in
                !hasShownWordToday(wordId: word.id?.uuidString ?? "") &&
                !availableWords.contains(where: { $0.id == word.id })
            }
            availableWords.append(contentsOf: filteredWords.shuffled().prefix(count - availableWords.count))
        }
        
        return Array(availableWords.shuffled().prefix(count))
    }
    
    private func hasShownWordToday(wordId: String) -> Bool {
        return UDService.shownWordIdsToday.contains(wordId)
    }
    
    private func markWordAsShown(wordId: String) {
        var shownWords = UDService.shownWordIdsToday
        if !shownWords.contains(wordId) {
            shownWords.append(wordId)
            UDService.shownWordIdsToday = shownWords
        }
    }
    
    private func resetDailyTracking() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UDService.lastWordStudyNotificationDate
        
        if lastDate == nil || !Calendar.current.isDate(lastDate!, inSameDayAs: today) {
            UDService.shownWordIdsToday = []
            UDService.lastWordStudyNotificationDate = today
        }
    }
} 

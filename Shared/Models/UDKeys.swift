//
//  UDKeys.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum UDKeys {
    static let isShowingRating = "isShowingRating"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userDisplayName = "userDisplayName"
    static let userNickname = "userNickname"

    // Notification Settings
    static let dailyRemindersEnabled = "dailyRemindersEnabled"
    static let difficultWordsEnabled = "difficultWordsEnabled"
    static let difficultWordsAlertsEnabled = "difficultWordsAlertsEnabled"
    static let dailyRemindersTime = "dailyRemindersTime"
    static let difficultWordsTime = "difficultWordsTime"
    static let wordStudyNotificationsEnabled = "wordStudyNotificationsEnabled"
    static let lastWordStudyNotificationDate = "lastWordStudyNotificationDate"
    static let shownWordIdsToday = "shownWordIdsToday"

    // Practice Settings
    static let practiceItemCount = "practiceItemCount"
    static let quizLanguageFilter = "quizLanguageFilter"

    // Translation Settings
    static let inputLanguage = "inputLanguage"
    static let idiomInputLanguage = "idiomInputLanguage"

    // TTS Settings
    static let selectedTTSProvider = "selectedTTSProvider"
    static let selectedSpeechifyVoice = "selectedSpeechifyVoice"
    static let selectedSpeechifyModel = "selectedSpeechifyModel"
    static let ttsSpeechRate = "tts_speech_rate"
    static let ttsVolume = "tts_volume"

    // Rating Banner Settings
    static let lastRatingRequestDate = "lastRatingRequestDate"
    static let lastAppOpenDate = "lastAppOpenDate"
    static let ratingRequestCount = "ratingRequestCount"
    static let hasRatedApp = "hasRatedApp"

    // Coffee Banner Settings
    static let lastCoffeeRequestDate = "lastCoffeeRequestDate"
    static let coffeeRequestCount = "coffeeRequestCount"
    static let hasShownCoffeeThisWeek = "hasShownCoffeeThisWeek"
    static let sessionStartTime = "sessionStartTime"
    static let selectedTTSRegion = "selectedTTSRegion"

    // Firebase Settings
    static let deviceID = "DeviceID"
    static let fcmToken = "FCMToken"
    
    // Image Onboarding
    static let imageOnboardingShown = "imageOnboardingShown"
    
    // AI Paywall Content Cache
    static let aiPaywallContent = "aiPaywallContent"
    static let aiPaywallContentTimestamp = "aiPaywallContentTimestamp"
    
    // Music Suggestions Cache
    static let musicSuggestionsCache = "musicSuggestionsCache"
    static let musicSuggestionsCacheTimestamp = "musicSuggestionsCacheTimestamp"
    
    // Apple Music
    static let appleMusicAuthorized = "apple_music_authorized"
}

enum UDService {
    static var isShowingRating: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.isShowingRating) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.isShowingRating) }
    }

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.hasCompletedOnboarding) }
    }

    static var userDisplayName: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.userDisplayName) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.userDisplayName) }
    }

    static var userNickname: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.userNickname) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.userNickname) }
    }

    // Notification Settings
    static var dailyRemindersEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.dailyRemindersEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.dailyRemindersEnabled) }
    }

    static var difficultWordsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.difficultWordsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.difficultWordsEnabled) }
    }

    static var difficultWordsAlertsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.difficultWordsAlertsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.difficultWordsAlertsEnabled) }
    }
    
    static var dailyRemindersTime: Date {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.dailyRemindersTime)
            // Default to 8:00 PM if no time is set
            if timeInterval == 0 {
                let calendar = Calendar.current
                let defaultTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
                return defaultTime
            }
            return Date(timeIntervalSince1970: timeInterval)
        }
        set { UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: UDKeys.dailyRemindersTime) }
    }
    
    static var difficultWordsTime: Date {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.difficultWordsTime)
            // Default to 4:00 PM if no time is set
            if timeInterval == 0 {
                let calendar = Calendar.current
                let defaultTime = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
                return defaultTime
            }
            return Date(timeIntervalSince1970: timeInterval)
        }
        set { UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: UDKeys.difficultWordsTime) }
    }
    
    static var wordStudyNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.wordStudyNotificationsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.wordStudyNotificationsEnabled) }
    }
    
    static var lastWordStudyNotificationDate: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.lastWordStudyNotificationDate)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: UDKeys.lastWordStudyNotificationDate)
        }
    }
    
    static var shownWordIdsToday: [String] {
        get { UserDefaults.standard.stringArray(forKey: UDKeys.shownWordIdsToday) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.shownWordIdsToday) }
    }

    // Practice Settings
    static var practiceItemCount: Int {
        get { UserDefaults.standard.integer(forKey: UDKeys.practiceItemCount) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.practiceItemCount) }
    }

    static var inputLanguage: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.inputLanguage) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.inputLanguage) }
    }
    
    static var quizLanguageFilter: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.quizLanguageFilter) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.quizLanguageFilter) }
    }

    static var idiomInputLanguage: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.idiomInputLanguage) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.idiomInputLanguage) }
    }

    // TTS Settings
    static var selectedTTSProvider: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.selectedTTSProvider) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.selectedTTSProvider) }
    }

    static var selectedSpeechifyVoice: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.selectedSpeechifyVoice) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.selectedSpeechifyVoice) }
    }

    static var selectedSpeechifyModel: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.selectedSpeechifyModel) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.selectedSpeechifyModel) }
    }

    static var ttsSpeechRate: Float {
        get { UserDefaults.standard.float(forKey: UDKeys.ttsSpeechRate) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.ttsSpeechRate) }
    }

    static var ttsVolume: Float {
        get { UserDefaults.standard.float(forKey: UDKeys.ttsVolume) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.ttsVolume) }
    }

    // Rating Banner Settings
    static var lastRatingRequestDate: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.lastRatingRequestDate)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: UDKeys.lastRatingRequestDate)
        }
    }

    static var lastAppOpenDate: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.lastAppOpenDate)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: UDKeys.lastAppOpenDate)
        }
    }

    static var ratingRequestCount: Int {
        get { UserDefaults.standard.integer(forKey: UDKeys.ratingRequestCount) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.ratingRequestCount) }
    }

    static var hasRatedApp: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.hasRatedApp) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.hasRatedApp) }
    }

    // Coffee Banner Settings
    static var lastCoffeeRequestDate: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.lastCoffeeRequestDate)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(
                    date.timeIntervalSince1970,
                    forKey: UDKeys.lastCoffeeRequestDate
                )
            } else {
                UserDefaults.standard.set(0, forKey: UDKeys.lastCoffeeRequestDate)
            }
        }
    }

    static var coffeeRequestCount: Int {
        get { UserDefaults.standard.integer(forKey: UDKeys.coffeeRequestCount) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.coffeeRequestCount) }
    }

    static var hasShownCoffeeThisWeek: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.hasShownCoffeeThisWeek) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.hasShownCoffeeThisWeek) }
    }

    static var sessionStartTime: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.sessionStartTime)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(
                newValue?.timeIntervalSince1970 ?? 0,
                forKey: UDKeys.sessionStartTime
            )
        }
    }

    static var selectedTTSRegion: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.selectedTTSRegion) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.selectedTTSRegion) }
    }

    // Firebase Settings
    static var deviceID: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.deviceID) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.deviceID) }
    }

    static var fcmToken: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.fcmToken) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.fcmToken) }
    }
    
    // Image Onboarding
    static var imageOnboardingShown: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.imageOnboardingShown) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.imageOnboardingShown) }
    }
    
    // AI Paywall Content Cache
    static var aiPaywallContentData: Data? {
        get { UserDefaults.standard.data(forKey: UDKeys.aiPaywallContent) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.aiPaywallContent) }
    }
    
    static var aiPaywallContentTimestamp: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.aiPaywallContentTimestamp)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: UDKeys.aiPaywallContentTimestamp)
        }
    }
    
    // Music Suggestions Cache
    static var musicSuggestionsCacheData: Data? {
        get { UserDefaults.standard.data(forKey: UDKeys.musicSuggestionsCache) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.musicSuggestionsCache) }
    }
    
    static var musicSuggestionsCacheTimestamp: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.musicSuggestionsCacheTimestamp)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: UDKeys.musicSuggestionsCacheTimestamp)
        }
    }

    // Apple Music
    static var appleMusicAuthorized: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.appleMusicAuthorized) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.appleMusicAuthorized) }
    }
}

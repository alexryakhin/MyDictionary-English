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

    // Practice Settings
    static let practiceItemCount = "practiceItemCount"

    // Translation Settings
    static let translateDefinitions = "translateDefinitions"
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
    static let selectedEnglishAccent = "selectedEnglishAccent"

    // Firebase Settings
    static let deviceID = "DeviceID"
    static let fcmToken = "FCMToken"
    
    // AI Service Usage Tracking
    static let aiUsageCount = "aiUsageCount"
    static let aiUsageDate = "aiUsageDate"
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

    // Practice Settings
    static var practiceItemCount: Int {
        get { UserDefaults.standard.integer(forKey: UDKeys.practiceItemCount) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.practiceItemCount) }
    }

    // Translation Settings
    static var translateDefinitions: Bool {
        get { UserDefaults.standard.bool(forKey: UDKeys.translateDefinitions) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.translateDefinitions) }
    }

    static var inputLanguage: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.inputLanguage) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.inputLanguage) }
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

    static var selectedEnglishAccent: String? {
        get { UserDefaults.standard.string(forKey: UDKeys.selectedEnglishAccent) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.selectedEnglishAccent) }
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
    
    // AI Service Usage Tracking
    static var aiUsageCount: Int {
        get { UserDefaults.standard.integer(forKey: UDKeys.aiUsageCount) }
        set { UserDefaults.standard.set(newValue, forKey: UDKeys.aiUsageCount) }
    }
    
    static var aiUsageDate: Date? {
        get {
            let timeInterval = UserDefaults.standard.double(forKey: UDKeys.aiUsageDate)
            return timeInterval > 0 ? Date(timeIntervalSince1970: timeInterval) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: UDKeys.aiUsageDate)
        }
    }
}

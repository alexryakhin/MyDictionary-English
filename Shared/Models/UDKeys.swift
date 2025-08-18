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

    static let showIdiomsTab = "showIdiomsTab"

    // Notification Settings
    static let dailyRemindersEnabled = "dailyRemindersEnabled"
    static let difficultWordsEnabled = "difficultWordsEnabled"
    static let difficultWordsAlertsEnabled = "difficultWordsAlertsEnabled"
    
    // Practice Settings
    static let practiceWordCount = "practiceWordCount"
    static let practiceHardWordsOnly = "practiceHardWordsOnly"
    
    // Translation Settings
    static let translateDefinitions = "translateDefinitions"
    static let inputLanguage = "inputLanguage"
    
    // Rating Banner Settings
    static let lastRatingRequestDate = "lastRatingRequestDate"
    static let ratingRequestCount = "ratingRequestCount"
    static let hasRatedApp = "hasRatedApp"
    
    // Coffee Banner Settings
    static let lastCoffeeRequestDate = "lastCoffeeRequestDate"
    static let coffeeRequestCount = "coffeeRequestCount"
    static let hasShownCoffeeThisWeek = "hasShownCoffeeThisWeek"
    static let sessionStartTime = "sessionStartTime"
    static let selectedEnglishAccent = "selectedEnglishAccent"
}

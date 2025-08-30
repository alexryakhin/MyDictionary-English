//
//  AIUsageTracker.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

final class AIUsageTracker {
    
    static let shared = AIUsageTracker()
    
    private let dailyLimit = 10
    private let subscriptionService = SubscriptionService.shared
    
    private init() {}
    
    /// Checks if the user can make an AI request
    /// - Returns: true if user can make AI request, false otherwise
    func canMakeAIRequest() -> Bool {
        // Pro users have unlimited access
        if subscriptionService.isProUser {
            return true
        }
        
        // Check if it's a new day
        let today = Calendar.current.startOfDay(for: Date())
        let lastUsageDate = UDService.aiUsageDate ?? Date.distantPast
        let lastUsageDay = Calendar.current.startOfDay(for: lastUsageDate)
        
        // If it's a new day, reset the count
        if !Calendar.current.isDate(today, inSameDayAs: lastUsageDay) {
            UDService.aiUsageCount = 0
            UDService.aiUsageDate = today
            return true
        }
        
        // Check if user has reached daily limit
        return UDService.aiUsageCount < dailyLimit
    }
    
    /// Records an AI request usage
    func recordAIUsage() {
        // Pro users don't need tracking
        if subscriptionService.isProUser {
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastUsageDate = UDService.aiUsageDate ?? Date.distantPast
        let lastUsageDay = Calendar.current.startOfDay(for: lastUsageDate)
        
        // If it's a new day, reset the count
        if !Calendar.current.isDate(today, inSameDayAs: lastUsageDay) {
            UDService.aiUsageCount = 1
            UDService.aiUsageDate = today
        } else {
            // Increment the count for the same day
            UDService.aiUsageCount += 1
        }
    }
    
    /// Gets the remaining AI requests for today
    /// - Returns: Number of remaining requests (0 for Pro users, actual count for non-Pro users)
    func getRemainingRequests() -> Int {
        if subscriptionService.isProUser {
            return 0 // 0 means unlimited for Pro users
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastUsageDate = UDService.aiUsageDate ?? Date.distantPast
        let lastUsageDay = Calendar.current.startOfDay(for: lastUsageDate)
        
        // If it's a new day, return full limit
        if !Calendar.current.isDate(today, inSameDayAs: lastUsageDay) {
            return dailyLimit
        }
        
        return max(0, dailyLimit - UDService.aiUsageCount)
    }
    
    /// Gets the total daily limit
    /// - Returns: Daily limit for non-Pro users
    func getDailyLimit() -> Int {
        return dailyLimit
    }
}

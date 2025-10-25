//
//  PaywallContentService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import SwiftUI

final class PaywallContentService: ObservableObject {
    static let shared = PaywallContentService()
    
    @Published var aiContent: AIPaywallContent?
    @Published var isLoading = false
    @Published var hasGenerated = false
    
    private let aiService = AIService.shared
    private let onboardingService = OnboardingService.shared
    private let cacheDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    private init() {
        loadCachedContent()
    }
    
    /// Checks if AI paywall generation is needed based on user profile, subscription status, and cache age
    func shouldGeneratePaywall() -> Bool {
        // Check if user has profile data
        guard onboardingService.userProfile != nil else {
            return false
        }
        
        // Don't generate for Pro users
        guard !SubscriptionService.shared.isProUser else {
            return false
        }
        
        // Check if AI service is ready
        guard aiService.isInitialized else {
            return false
        }
        
        // Check if we need to generate (no cache or expired)
        return !hasValidCache()
    }
    
    /// Checks if we have valid cached content that hasn't expired
    private func hasValidCache() -> Bool {
        guard let cachedContent = getCachedContent() else {
            return false
        }
        
        return !isCacheExpired()
    }
    
    /// Checks if paywall generation is needed and generates it if so
    func checkAndGenerateIfNeeded() async {
        guard shouldGeneratePaywall() else {
            return
        }
        
        await generatePaywallContent()
    }
    
    /// Generates AI paywall content and caches it
    func generatePaywallContent() async {
        guard let userProfile = onboardingService.userProfile else {
            print("⚠️ [PaywallContentService] No user profile available for AI generation")
            return
        }
        
        // Check if we already have valid cached content
        if let cachedContent = getCachedContent(), !isCacheExpired() {
            aiContent = cachedContent
            hasGenerated = true
            return
        }
        
        isLoading = true
        
        do {
            let userLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            let content = try await aiService.generatePaywallContent(
                userProfile: userProfile,
                userLanguage: userLanguage
            )
            
            aiContent = content
            hasGenerated = true
            saveToCache(content)
            
            print("✅ [PaywallContentService] AI paywall content generated successfully")
        } catch {
            print("❌ [PaywallContentService] Failed to generate AI paywall content: \(error)")
            // Don't set hasGenerated = true on failure, so we can retry later
        }
        
        isLoading = false
    }
    
    /// Gets cached content if available and not expired
    func getCachedContent() -> AIPaywallContent? {
        guard let data = UDService.aiPaywallContentData else { return nil }
        
        do {
            let content = try JSONDecoder().decode(AIPaywallContent.self, from: data)
            return content
        } catch {
            print("❌ [PaywallContentService] Failed to decode cached content: \(error)")
            return nil
        }
    }
    
    /// Clears the cache (called when user profile changes significantly)
    func clearCache() {
        UDService.aiPaywallContentData = nil
        UDService.aiPaywallContentTimestamp = nil
        aiContent = nil
        hasGenerated = false
        print("🗑️ [PaywallContentService] Cache cleared")
    }
    
    private func loadCachedContent() {
        if let cachedContent = getCachedContent(), !isCacheExpired() {
            aiContent = cachedContent
            hasGenerated = true
        }
    }
    
    private func saveToCache(_ content: AIPaywallContent) {
        do {
            let data = try JSONEncoder().encode(content)
            UDService.aiPaywallContentData = data
            UDService.aiPaywallContentTimestamp = Date()
            print("💾 [PaywallContentService] Content cached successfully")
        } catch {
            print("❌ [PaywallContentService] Failed to cache content: \(error)")
        }
    }
    
    private func isCacheExpired() -> Bool {
        guard let timestamp = UDService.aiPaywallContentTimestamp else { return true }
        return Date().timeIntervalSince(timestamp) > cacheDuration
    }
}

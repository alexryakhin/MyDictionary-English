//
//  PaywallContentService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import SwiftUI
import Combine

final class PaywallContentService: ObservableObject {
    static let shared = PaywallContentService()
    
    @Published var aiContent: AIPaywallContent?
    @Published var isLoading = false
    @Published var hasGenerated = false
    
    private let aiService = AIService.shared
    private let onboardingService = OnboardingService.shared
    private let subscriptionService = SubscriptionService.shared
    private let cacheDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadCachedContent()
        setupSubscriptionObserver()
    }
    
    /// Checks if AI paywall generation is needed based on user profile, subscription status, and cache age
    func shouldGeneratePaywall() -> Bool {
        // Check if user has profile data
        guard onboardingService.userProfile != nil else {
            print("⚠️ [PaywallContentService] No user profile - skipping AI generation")
            return false
        }
        
        // Don't generate for Pro users
        guard !subscriptionService.isProUser else {
            print("✅ [PaywallContentService] User is PRO - skipping AI generation")
            return false
        }
        
        // Check if AI service is ready
        guard aiService.isInitialized else {
            print("⚠️ [PaywallContentService] AI service not ready - skipping AI generation")
            return false
        }
        
        // Check if we need to generate (no cache or expired)
        let needsGeneration = !hasValidCache()
        print("🔍 [PaywallContentService] Should generate AI paywall: \(needsGeneration)")
        return needsGeneration
    }
    
    /// Checks if we have valid cached content that hasn't expired
    private func hasValidCache() -> Bool {
        guard let cachedContent = getCachedContent() else {
            return false
        }
        
        return !isCacheExpired()
    }
    
    /// Sets up Combine observer to watch for subscription status changes
    private func setupSubscriptionObserver() {
        // Observe both loading state and Pro user status
        Publishers.CombineLatest(
            subscriptionService.$isLoading,
            subscriptionService.$_isProUser
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] isLoading, isProUser in
            // Only check when subscription service finishes loading
            if !isLoading {
                print("🔄 [PaywallContentService] Subscription status updated - isProUser: \(isProUser)")
                Task { @MainActor in
                    await self?.checkAndGenerateIfNeeded()
                }
            }
        }
        .store(in: &cancellables)
    }
    
    /// Checks if paywall generation is needed and generates it if so
    func checkAndGenerateIfNeeded() async {
        guard shouldGeneratePaywall() else {
            return
        }
        
        await generatePaywallContent()
    }
    
    /// Manually triggers a check for paywall generation (useful for immediate checks)
    func forceCheckAndGenerateIfNeeded() async {
        // Wait for subscription service to finish loading if it's still loading
        if subscriptionService.isLoading {
            // Wait for the next subscription status update via Combine
            return
        }
        
        await checkAndGenerateIfNeeded()
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
            let userLanguage = InputLanguage(rawValue: Locale.current.language.languageCode?.identifier ?? "en") ?? .english
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

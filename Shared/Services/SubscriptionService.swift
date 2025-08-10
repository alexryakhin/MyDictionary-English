//
//  SubscriptionService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import RevenueCat
import Combine

// MARK: - Subscription Plans

enum SubscriptionPlan: String, CaseIterable {
    case monthly = "pro_monthly"
    case yearly = "pro_yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly Pro"
        case .yearly: return "Yearly Pro"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$4.99/month"
        case .yearly: return "$39.99/year"
        }
    }
    
    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Save 33%"
        }
    }
    
    var productId: String {
        switch self {
        case .monthly: return "com.dor.mydictionary.pro.monthly"
        case .yearly: return "com.dor.mydictionary.pro.yearly"
        }
    }
}

// MARK: - Subscription Features

enum SubscriptionFeature: String, CaseIterable {
    case googleSync = "google_sync"
    case unlimitedExport = "unlimited_export"
    case createSharedDictionaries = "create_shared_dictionaries"
    case advancedAnalytics = "advanced_analytics"
    case prioritySupport = "priority_support"
    
    var displayName: String {
        switch self {
        case .googleSync: return "Google Sync"
        case .unlimitedExport: return "Unlimited Export"
        case .createSharedDictionaries: return "Create Shared Dictionaries"
        case .advancedAnalytics: return "Advanced Analytics"
        case .prioritySupport: return "Priority Support"
        }
    }
    
    var description: String {
        switch self {
        case .googleSync: return "Sync your words across all devices using Google Cloud"
        case .unlimitedExport: return "Export unlimited words to CSV"
        case .createSharedDictionaries: return "Create and manage shared dictionaries with collaborators"
        case .advancedAnalytics: return "Detailed progress tracking and insights"
        case .prioritySupport: return "Get priority support when you need help"
        }
    }
    
    var iconName: String {
        switch self {
        case .googleSync: return "cloud.fill"
        case .unlimitedExport: return "square.and.arrow.up"
        case .createSharedDictionaries: return "person.2.fill"
        case .advancedAnalytics: return "chart.bar.fill"
        case .prioritySupport: return "star.fill"
        }
    }
}

// MARK: - Subscription Service

final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published private(set) var isProUser = false
    @Published private(set) var currentPlan: SubscriptionPlan?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupRevenueCat()
    }
    
    // MARK: - RevenueCat Setup
    
    private func setupRevenueCat() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        
        // Temporary flag to disable RevenueCat for testing
        #if DISABLE_REVENUECAT
        print("⚠️ [SubscriptionService] RevenueCat disabled for testing")
        return
        #endif
        
        let configuration = Configuration.Builder(withAPIKey: "appl_qTlDIApNdWUjhHvAXnBPyGdYFgx")
            .with(storeKitVersion: .storeKit2)
            .build()
        
        Purchases.configure(with: configuration)
        // Check initial subscription status
        Task { @MainActor in
            try await updateSubscriptionStatus(customerInfo: Purchases.shared.customerInfo())
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Subscription Status
    
    @MainActor
    private func updateSubscriptionStatus(customerInfo: CustomerInfo) {
        isProUser = !customerInfo.entitlements.active.isEmpty
        currentPlan = getCurrentPlan(from: customerInfo)
        print("🔹 [SubscriptionService] Subscription status updated - isPro: \(isProUser)")
    }
    
    private func getCurrentPlan(from customerInfo: CustomerInfo) -> SubscriptionPlan? {
        for plan in SubscriptionPlan.allCases {
            if customerInfo.entitlements[plan.rawValue]?.isActive == true {
                return plan
            }
        }
        return nil
    }
    
    @MainActor
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
            errorMessage = "Failed to check subscription status: \(error.localizedDescription)"
            print("❌ [SubscriptionService] Failed to check subscription status: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Methods
    
    @MainActor
    func purchasePlan(_ plan: SubscriptionPlan) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let offering = offerings.current else {
                throw SubscriptionError.noOfferingsAvailable
            }
            
            guard let package = offering.availablePackages.first(where: { $0.identifier == plan.rawValue }) else {
                throw SubscriptionError.packageNotFound
            }
            
            let customerInfo = try await Purchases.shared.purchase(package: package)
            try await updateSubscriptionStatus(customerInfo: Purchases.shared.customerInfo())

            print("✅ [SubscriptionService] Successfully purchased \(plan.displayName)")
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ [SubscriptionService] Purchase failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func restorePurchases() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(customerInfo: customerInfo)
            
            if isProUser {
                print("✅ [SubscriptionService] Purchases restored successfully")
            } else {
                print("ℹ️ [SubscriptionService] No active purchases found")
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
            print("❌ [SubscriptionService] Restore failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Feature Access
    
    func hasAccess(to feature: SubscriptionFeature) -> Bool {
        return isProUser
    }
    
    func canUseGoogleSync() -> Bool {
        return hasAccess(to: .googleSync)
    }
    
    func canExportUnlimitedWords() -> Bool {
        return hasAccess(to: .unlimitedExport)
    }
    
    func canCreateSharedDictionaries() -> Bool {
        return hasAccess(to: .createSharedDictionaries)
    }
    
    func canAccessAdvancedAnalytics() -> Bool {
        return hasAccess(to: .advancedAnalytics)
    }
    
    // MARK: - Export Limits
    
    func getExportLimit() -> Int {
        return canExportUnlimitedWords() ? Int.max : 50
    }
    
    func canExportWords(_ count: Int) -> Bool {
        return count <= getExportLimit()
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case noOfferingsAvailable
    case packageNotFound
    case purchaseFailed
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .noOfferingsAvailable:
            return "No subscription offerings are currently available"
        case .packageNotFound:
            return "The requested subscription package was not found"
        case .purchaseFailed:
            return "The purchase could not be completed"
        case .restoreFailed:
            return "Failed to restore previous purchases"
        }
    }
}

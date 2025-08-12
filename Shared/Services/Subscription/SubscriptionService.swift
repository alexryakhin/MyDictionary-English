//
//  SubscriptionService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import RevenueCat
import Combine
import FirebaseFirestore

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

final class SubscriptionService: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = SubscriptionService()

    @Published private(set) var isProUser = false
    @Published private(set) var currentPlan: SubscriptionPlan?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
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

        let configuration = Configuration.Builder(withAPIKey: AppConfig.RevenueCat.publicSDKKey)
            .with(storeKitVersion: .storeKit2)
            .build()

        Purchases.configure(with: configuration)

        // Set this service as the delegate to receive purchase updates
        Purchases.shared.delegate = self

        // Check initial subscription status only if user is authenticated
        Task { @MainActor in
            if AuthenticationService.shared.isSignedIn {
                // Set up cross-platform App User ID when user signs in
                await setupAppUserID()
                
                let customerInfo = try await Purchases.shared.customerInfo()
                updateSubscriptionStatus(customerInfo: customerInfo)
                await checkSubscriptionStatus()
            } else {
                // Reset subscription status for anonymous users
                isProUser = false
                currentPlan = nil
                print("⚠️ [SubscriptionService] User not authenticated - subscription disabled")
            }
        }
    }

    /// Sets up the App User ID for cross-platform subscription sharing
    func setupAppUserID() async {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            print("⚠️ [SubscriptionService] No user email available for App User ID setup")
            return
        }

        // Use email as the App User ID for cross-platform consistency
        // This ensures the same user gets the same subscription across iOS and Android
        do {
            let response = try await Purchases.shared.logIn(userEmail)
            print("✅ [SubscriptionService] App User ID set successfully: \(userEmail)")
            print("📱 [SubscriptionService] Customer info: \(response.customerInfo.originalAppUserId)")

            // Update subscription status after login
            await updateSubscriptionStatus(customerInfo: response.customerInfo)

            // Verify subscription ownership (but don't fail if verification fails)
            let isOwner = await verifySubscriptionOwnership()
            if !isOwner {
                print("⚠️ [SubscriptionService] Subscription ownership verification failed, but continuing...")
                // Don't return here, let the user continue
            }

            // Sync to Firestore
            await syncSubscriptionStatusToFirestore()

        } catch {
            print("❌ [SubscriptionService] Failed to set App User ID: \(error)")
        }
    }

    /// Logs out the current user from RevenueCat to prevent subscription sharing
    @MainActor
    func logoutFromRevenueCat() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            print("✅ [SubscriptionService] Logged out from RevenueCat")
            print("📱 [SubscriptionService] Customer info after logout: \(customerInfo.originalAppUserId)")

            // Reset subscription status immediately
            isProUser = false
            currentPlan = nil
            
            print("📉 [SubscriptionService] User lost Pro status due to logout")

        } catch {
            print("❌ [SubscriptionService] Failed to logout from RevenueCat: \(error)")
        }
    }

    // MARK: - RevenueCat Delegate Methods

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        print("🔔 [SubscriptionService] Received RevenueCat customer info update")
        Task { @MainActor in
            // Only update subscription status if user is authenticated
            if AuthenticationService.shared.isSignedIn {
                updateSubscriptionStatus(customerInfo: customerInfo)
            } else {
                print("⚠️ [SubscriptionService] Ignoring subscription update for anonymous user")
                isProUser = false
                currentPlan = nil
            }
        }
    }

    func purchases(_ purchases: Purchases, readyForPromotedProduct product: StoreProduct, purchase: @escaping StartPurchaseBlock) {
        print("🔔 [SubscriptionService] Ready for promoted product: \(product.productIdentifier)")
        purchase { transaction, customerInfo, error, isCompleted in
            if let error = error {
                print("❌ [SubscriptionService] Promoted purchase failed: \(error)")
            } else {
                print("✅ [SubscriptionService] Promoted purchase successful")
            }
        }
    }

    // MARK: - Subscription Status

    @MainActor
    private func updateSubscriptionStatus(customerInfo: CustomerInfo) {
        let wasProUser = isProUser
        isProUser = !customerInfo.entitlements.active.isEmpty
        currentPlan = getCurrentPlan(from: customerInfo)

        print("🔹 [SubscriptionService] Subscription status updated - isPro: \(isProUser)")

        // Log when subscription status changes
        if wasProUser != isProUser {
            if isProUser {
                print("🎉 [SubscriptionService] User became Pro user!")
            } else {
                print("📉 [SubscriptionService] User lost Pro status")
            }

            // Sync subscription status to Firestore
            Task {
                await syncSubscriptionStatusToFirestore()
            }
        }
    }

    /// Syncs subscription status to the user's Firestore document
    private func syncSubscriptionStatusToFirestore() async {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            print("⚠️ [SubscriptionService] No user email available for subscription sync")
            return
        }

        do {
            let db = Firestore.firestore()

            // Get subscription expiry date from RevenueCat
            let customerInfo = try await Purchases.shared.customerInfo()
            let expiryDate = customerInfo.entitlements.active.values.first?.expirationDate

            // Use setData with merge to create document if it doesn't exist
            try await db.collection("users").document(userEmail).setData([
                "subscriptionStatus": isProUser ? "pro" : "free",
                "subscriptionPlan": currentPlan?.rawValue ?? "none",
                "subscriptionExpiryDate": expiryDate,
                "lastUpdated": FieldValue.serverTimestamp()
            ], merge: true)

            print("✅ [SubscriptionService] Subscription status synced to Firestore")

        } catch {
            print("❌ [SubscriptionService] Failed to sync subscription status: \(error)")
        }
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

            let response = try await Purchases.shared.purchase(package: package)
            updateSubscriptionStatus(customerInfo: response.customerInfo)

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


    // MARK: - Export Limits

    func getExportLimit() -> Int {
        return isProUser ? Int.max : AppConfig.Features.freeUserExportLimit
    }

    func canExportWords(_ count: Int) -> Bool {
        return count <= getExportLimit()
    }

    // MARK: - Shared Dictionary Limits

    func getSharedDictionaryLimit() -> Int {
        return isProUser ? Int.max : 1
    }

    func canCreateMoreSharedDictionaries(currentCount: Int) -> Bool {
        return currentCount < getSharedDictionaryLimit()
    }

    /// Public method to manually sync subscription status to Firestore
    func syncSubscriptionStatus() async {
        await syncSubscriptionStatusToFirestore()
    }

        /// Verifies that the current user actually owns the subscription
    /// This prevents subscription sharing between different accounts
    func verifySubscriptionOwnership() async -> Bool {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            print("⚠️ [SubscriptionService] No user email available for subscription verification")
            return false
        }
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Check if the current App User ID matches the user's email
            let currentAppUserId = customerInfo.originalAppUserId
            
            // For new logins, the App User ID might still be anonymous initially
            // We need to check if the user has active subscriptions first
            let hasActiveSubscription = !customerInfo.entitlements.active.isEmpty
            
            print("🔍 [SubscriptionService] Subscription ownership check:")
            print("   - Current App User ID: \(currentAppUserId)")
            print("   - User Email: \(userEmail)")
            print("   - Has Active Subscription: \(hasActiveSubscription)")
            
            // If user has no active subscription, they can't be an owner
            if !hasActiveSubscription {
                print("ℹ️ [SubscriptionService] No active subscription found")
                return true // Allow this, no ownership conflict
            }
            
            // If App User ID is still anonymous but user has subscription, 
            // we need to complete the login process
            if currentAppUserId.hasPrefix("$RCAnonymousID:") {
                print("⚠️ [SubscriptionService] App User ID still anonymous, completing login...")
                // Try to log in again to get the proper App User ID
                let response = try await Purchases.shared.logIn(userEmail)
                let newAppUserId = response.customerInfo.originalAppUserId
                
                if newAppUserId == userEmail {
                    print("✅ [SubscriptionService] Login completed successfully")
                    return true
                } else {
                    print("⚠️ [SubscriptionService] Login failed to set proper App User ID")
                    return false
                }
            }
            
            // Check if App User ID matches email
            let isOwner = currentAppUserId == userEmail
            
            if !isOwner {
                print("⚠️ [SubscriptionService] Subscription ownership mismatch - logging out")
                await logoutFromRevenueCat()
                return false
            }
            
            return true
            
        } catch {
            print("❌ [SubscriptionService] Failed to verify subscription ownership: \(error)")
            return false
        }
    }
    
    /// Checks if the current user is anonymous (not authenticated)
    /// Anonymous users should not have access to subscriptions
    private func isAnonymousUser() -> Bool {
        return !AuthenticationService.shared.isSignedIn || AuthenticationService.shared.userEmail == nil
    }
    
    /// Checks if user can access advanced analytics features
    func canAccessAdvancedAnalytics() -> Bool {
        return isProUser
    }

    /// Immediately resets subscription status when user signs out
    /// This ensures Pro features are immediately disabled
    @MainActor
    func resetSubscriptionStatusOnSignOut() {
        print("🔄 [SubscriptionService] Resetting subscription status due to sign out")
        isProUser = false
        currentPlan = nil
    }
    
    /// Forces a refresh of subscription status and authentication check
    /// Useful for debugging and ensuring UI is up to date
    @MainActor
    func forceRefreshSubscriptionStatus() {
        print("🔄 [SubscriptionService] Force refreshing subscription status")
        
        // Check authentication status
        let isAuthenticated = AuthenticationService.shared.isSignedIn
        let hasEmail = AuthenticationService.shared.userEmail != nil
        
        if !isAuthenticated || !hasEmail {
            print("⚠️ [SubscriptionService] User not authenticated - resetting to free")
            isProUser = false
            currentPlan = nil
        } else {
            print("✅ [SubscriptionService] User authenticated - checking subscription")
            // Trigger a subscription check
            Task {
                await checkSubscriptionStatus()
            }
        }
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

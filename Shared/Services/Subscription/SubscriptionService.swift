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

// MARK: - Subscription Plan Model

struct SubscriptionPlan: Identifiable, Hashable {
    let id: String // Product ID
    let product: StoreProduct
    let displayName: String
    let price: String
    let savings: String?

    init(product: StoreProduct) {
        self.id = product.productIdentifier
        self.product = product
        self.displayName = product.localizedTitle
        self.price = product.localizedPriceString

        // Calculate savings for yearly plans
        if product.subscriptionPeriod?.unit == .year {
            // Compare with monthly price to show savings
            self.savings = Loc.Subscription.Paywall.savePercentage("37%")
        } else {
            self.savings = nil
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Subscription Features

enum SubscriptionFeature: String, CaseIterable {
    case aiDefinitions = "ai_definitions"
    case aiQuizzes = "ai_quizzes"
    case images = "images"
    case wordCollections = "word_collections"
    case premiumTTS = "premium_tts"
    case unlimitedExport = "unlimited_export"
    case createSharedDictionaries = "create_shared_dictionaries"
    case tagManagement = "tag_management"
    case advancedAnalytics = "advanced_analytics"
    case prioritySupport = "priority_support"

    var displayName: String {
        switch self {
        case .aiDefinitions: Loc.Subscription.ProFeatures.aiDefinitions
        case .aiQuizzes: Loc.Subscription.ProFeatures.aiQuizzes
        case .premiumTTS: Loc.Subscription.ProFeatures.speechifyTts
        case .unlimitedExport: Loc.Subscription.ProFeatures.unlimitedExport
        case .createSharedDictionaries: Loc.Subscription.ProFeatures.createSharedDictionaries
        case .tagManagement: Loc.Subscription.ProFeatures.tagManagement
        case .advancedAnalytics: Loc.Subscription.ProFeatures.advancedAnalytics
        case .prioritySupport: Loc.Subscription.ProFeatures.prioritySupport
        case .images: Loc.Subscription.ProFeatures.images
        case .wordCollections: Loc.Subscription.ProFeatures.wordCollections
        }
    }

    var description: String {
        switch self {
        case .aiDefinitions: Loc.Subscription.ProFeatures.aiDefinitionsDescription
        case .aiQuizzes: Loc.Subscription.ProFeatures.aiQuizzesDescription
        case .premiumTTS: Loc.Subscription.ProFeatures.speechifyTtsDescription
        case .unlimitedExport: Loc.Subscription.ProFeatures.syncWordsAcrossDevices
        case .createSharedDictionaries: Loc.Subscription.ProFeatures.createManageSharedDictionaries
        case .tagManagement: Loc.Subscription.ProFeatures.organizeWordsWithTags
        case .advancedAnalytics: Loc.Subscription.ProFeatures.detailedInsights
        case .prioritySupport: Loc.Subscription.ProFeatures.prioritySupportTeam
        case .images: Loc.Subscription.ProFeatures.imagesDescription
        case .wordCollections: Loc.Subscription.ProFeatures.wordCollectionsDescription
        }
    }

    var iconName: String {
        switch self {
        case .aiDefinitions: "character.magnify"
        case .aiQuizzes: "brain.head.profile"
        case .premiumTTS: "person.wave.2.fill"
        case .unlimitedExport: "square.and.arrow.up"
        case .createSharedDictionaries: "person.2.fill"
        case .tagManagement: "tag.fill"
        case .advancedAnalytics: "chart.bar.fill"
        case .prioritySupport: "star.fill"
        case .images: "photo.fill"
        case .wordCollections: "folder.fill"
        }
    }
}

// MARK: - Subscription Service

final class SubscriptionService: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = SubscriptionService()

    @Published private(set) var _isProUser = false // Internal storage for actual subscription status
    @Published private(set) var currentPlan: SubscriptionPlan?
    @Published private(set) var availablePlans: [SubscriptionPlan] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // Track if user is anonymous (not authenticated)
    @Published private(set) var isAnonymousUser = false
    
    // Debug mode for testing premium features locally
    @Published var debugPremiumMode = false

    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Returns true if user has Pro access (either through subscription or debug mode)
    var isProUser: Bool {
        return _isProUser || debugPremiumMode
    }

    // UserDefaults key for anonymous subscription status
    private let anonymousSubscriptionKey = "anonymous_subscription_status"
    private let anonymousSubscriptionExpiryKey = "anonymous_subscription_expiry"

    private override init() {
        super.init()
        setupRevenueCat()
    }

    // MARK: - RevenueCat Setup

    private func setupRevenueCat() {
        // DO NOT TRANSLATE DEBUG
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

        // Load products and check initial subscription status
        Task { @MainActor in
            // Load available products first
            await loadAvailableProducts()

            if AuthenticationService.shared.isSignedIn {
                // Set up cross-platform App User ID when user signs in
                await setupAppUserID()

                let customerInfo = try await Purchases.shared.customerInfo()
                updateSubscriptionStatus(customerInfo: customerInfo)
                await checkSubscriptionStatus()
            } else {
                // Reset subscription status for anonymous users
                _isProUser = false
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

        // Check if user had an anonymous subscription before signing in
        let hadAnonymousSubscription = loadAnonymousSubscriptionStatus()
        
        do {
            let response = try await Purchases.shared.logIn(userEmail)
            print("✅ [SubscriptionService] App User ID set successfully: \(userEmail)")
            print("📱 [SubscriptionService] Customer info: \(response.customerInfo.originalAppUserId)")

            // Update subscription status after login
            await updateSubscriptionStatus(customerInfo: response.customerInfo)

            // If user had an anonymous subscription, we need to handle it specially
            if hadAnonymousSubscription {
                print("🔄 [SubscriptionService] User had anonymous subscription - attempting to restore")
                
                // Try to restore purchases to get the subscription under the new App User ID
                do {
                    let restoreResponse = try await Purchases.shared.restorePurchases()
                    await updateSubscriptionStatus(customerInfo: restoreResponse)
                    print("✅ [SubscriptionService] Anonymous subscription successfully restored to authenticated account")
                } catch {
                    print("⚠️ [SubscriptionService] Failed to restore anonymous subscription: \(error)")
                    // Don't fail the sign-in process, but log the issue
                }
                
                // Clear the anonymous subscription status since we've handled it
                clearAnonymousSubscriptionStatus()
            }

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
            _isProUser = false
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
                _isProUser = false
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
        _isProUser = !customerInfo.entitlements.active.isEmpty
        currentPlan = getCurrentPlan(from: customerInfo)

        // Check if user is anonymous
        isAnonymousUser = !AuthenticationService.shared.isSignedIn

        print("🔹 [SubscriptionService] Subscription status updated - isPro: \(isProUser), isAnonymous: \(isAnonymousUser)")

        // Log when subscription status changes
        if wasProUser != isProUser {
            if isProUser {
                print("🎉 [SubscriptionService] User became Pro user!")

                // If user is anonymous, store subscription status locally
                if isAnonymousUser {
                    storeAnonymousSubscriptionStatus(customerInfo: customerInfo)
                }
            } else {
                print("📉 [SubscriptionService] User lost Pro status")

                // Clear anonymous subscription status if user lost access
                if isAnonymousUser {
                    clearAnonymousSubscriptionStatus()
                }
            }

            // Only sync to Firestore if user is authenticated
            if AuthenticationService.shared.isSignedIn {
                Task {
                    await syncSubscriptionStatusToFirestore()
                }
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
            let expiryDate = customerInfo.entitlements.active.values.first?.expirationDate ?? .now

            // Use setData with merge to create document if it doesn't exist
            try await db.collection("users").document(userEmail).setData([
                "subscriptionStatus": isProUser ? "pro" : "free",
                "subscriptionPlan": currentPlan?.id ?? "none",
                "subscriptionExpiryDate": Timestamp(date: expiryDate),
                "lastUpdated": FieldValue.serverTimestamp()
            ], merge: true)

            print("✅ [SubscriptionService] Subscription status synced to Firestore")

        } catch {
            print("❌ [SubscriptionService] Failed to sync subscription status: \(error)")
        }
    }

    private func getCurrentPlan(from customerInfo: CustomerInfo) -> SubscriptionPlan? {
        // If user has pro access, return the first available plan (or preferred plan)
        if customerInfo.entitlements["pro_access"]?.isActive == true {
            // Prefer yearly plan if available, otherwise return first plan
            return availablePlans.first { plan in
                plan.product.subscriptionPeriod?.unit == .year
            } ?? availablePlans.first
        }
        return nil
    }

    // MARK: - Anonymous Subscription Management

    private func storeAnonymousSubscriptionStatus(customerInfo: CustomerInfo) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: anonymousSubscriptionKey)

        // Store expiry date if available
        if let expiryDate = customerInfo.entitlements.active.values.first?.expirationDate {
            defaults.set(expiryDate.timeIntervalSince1970, forKey: anonymousSubscriptionExpiryKey)
        }

        print("✅ [SubscriptionService] Anonymous subscription status stored locally")
    }

    private func clearAnonymousSubscriptionStatus() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: anonymousSubscriptionKey)
        defaults.removeObject(forKey: anonymousSubscriptionExpiryKey)

        print("🗑️ [SubscriptionService] Anonymous subscription status cleared")
    }

    private func loadAnonymousSubscriptionStatus() -> Bool {
        let defaults = UserDefaults.standard

        // Check if subscription is active
        guard defaults.bool(forKey: anonymousSubscriptionKey) else {
            return false
        }

        // Check if subscription has expired
        if let expiryTimestamp = defaults.object(forKey: anonymousSubscriptionExpiryKey) as? TimeInterval {
            let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
            if Date() > expiryDate {
                // Subscription has expired, clear it
                clearAnonymousSubscriptionStatus()
                return false
            }
        }

        return true
    }

    /// Called when an anonymous user registers - syncs their subscription to their account
    func syncAnonymousSubscriptionToAccount() async {
        guard AuthenticationService.shared.isSignedIn else { return }

        // Check if user had an anonymous subscription
        let hadAnonymousSubscription = loadAnonymousSubscriptionStatus()

        if hadAnonymousSubscription {
            // Clear the anonymous subscription status since it's now tied to their account
            clearAnonymousSubscriptionStatus()

            // Sync subscription status to Firestore
            await syncSubscriptionStatusToFirestore()

            print("✅ [SubscriptionService] Anonymous subscription synced to user account")
        }
    }

    /// Check subscription status for both authenticated and anonymous users
    @MainActor
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.customerInfo()

            // If user is not authenticated, also check local anonymous subscription status
            if !AuthenticationService.shared.isSignedIn {
                let anonymousStatus = loadAnonymousSubscriptionStatus()
                if anonymousStatus {
                    _isProUser = true
                    print("✅ [SubscriptionService] Anonymous subscription status loaded from local storage")
                } else {
                    updateSubscriptionStatus(customerInfo: customerInfo)
                }
            } else {
                updateSubscriptionStatus(customerInfo: customerInfo)
            }
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

            // Find the package that matches our plan's product
            guard let package = offering.availablePackages.first(where: {
                $0.storeProduct.productIdentifier == plan.id
            }) else {
                throw SubscriptionError.packageNotFound
            }

            let response = try await Purchases.shared.purchase(package: package)
            updateSubscriptionStatus(customerInfo: response.customerInfo)

            print("✅ [SubscriptionService] Successfully purchased \(plan.displayName)")

            // Show different messaging based on authentication status
            if !AuthenticationService.shared.isSignedIn {
                print("ℹ️ [SubscriptionService] Anonymous purchase completed - user can register later for cross-platform access")
            }
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
            // this is likely a timing issue where RevenueCat hasn't updated yet
            if currentAppUserId.hasPrefix("$RCAnonymousID:") {
                print("⚠️ [SubscriptionService] App User ID still anonymous - this is normal during login")
                print("ℹ️ [SubscriptionService] RevenueCat will update the App User ID asynchronously")
                // Allow this to pass - the App User ID will be updated by RevenueCat
                return true
            }

            // Check if App User ID matches email
            let isOwner = currentAppUserId == userEmail

            if !isOwner {
                print("🚨 [SubscriptionService] SUBSCRIPTION OWNERSHIP MISMATCH DETECTED!")
                print("   - Expected owner: \(userEmail)")
                print("   - Actual owner: \(currentAppUserId)")
                print("   - Logging out to prevent subscription sharing")

                // Log the security event
                AnalyticsService.shared.logEvent(.subscriptionOwnershipMismatch)

                // Logout from RevenueCat to prevent access
                await logoutFromRevenueCat()

                // Show security alert to user
                await showSubscriptionOwnershipAlert()

                return false
            }

            return true

        } catch {
            print("❌ [SubscriptionService] Failed to verify subscription ownership: \(error)")
            return false
        }
    }

    /// Shows an alert when subscription ownership mismatch is detected
    @MainActor
    private func showSubscriptionOwnershipAlert() async {
        AlertCenter.shared.showAlert(with: .info(
            title: Loc.Auth.subscriptionAccessRestricted,
            message: Loc.Auth.subscriptionAssociatedDifferentAccount
        ))
    }

    // MARK: - Product Loading

    /// Loads available subscription products from RevenueCat
    @MainActor
    func loadAvailableProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let offerings = try await Purchases.shared.offerings()

            guard let currentOffering = offerings.current else {
                errorMessage = "No subscription offerings available"
                isLoading = false
                return
            }

            // Convert StoreProducts to SubscriptionPlans
            let plans = currentOffering.availablePackages.map { package in
                SubscriptionPlan(product: package.storeProduct)
            }

            availablePlans = plans

        } catch {
            errorMessage = "Failed to load subscription products: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Gets the default plan (usually yearly for better value)
    var defaultPlan: SubscriptionPlan? {
        return availablePlans.first { plan in
            plan.product.subscriptionPeriod?.unit == .year
        } ?? availablePlans.first
    }

    /// Checks if user can access advanced analytics features
    func canAccessAdvancedAnalytics() -> Bool {
        return isProUser
    }

    /// Immediately resets subscription status when user signs out
    /// This ensures Pro features are immediately disabled
    @MainActor
    func resetSubscriptionStatusOnSignOut() {
        _isProUser = false
        currentPlan = nil
    }

    /// Forces a refresh of subscription status and authentication check
    /// Useful for debugging and ensuring UI is up to date
    @MainActor
    func forceRefreshSubscriptionStatus() {
        // Check authentication status
        let isAuthenticated = AuthenticationService.shared.isSignedIn
        let hasEmail = AuthenticationService.shared.userEmail != nil

        if !isAuthenticated || !hasEmail {
            _isProUser = false
            currentPlan = nil
        } else {
            // Trigger a subscription check
            Task {
                await checkSubscriptionStatus()
            }
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: Error, LocalizedError {
    case noOfferingsAvailable
    case packageNotFound
    case purchaseFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .noOfferingsAvailable:
            return Loc.Errors.noOfferingsAvailable
        case .packageNotFound:
            return Loc.Errors.packageNotFound
        case .purchaseFailed:
            return Loc.Errors.purchaseFailed
        case .restoreFailed:
            return Loc.Errors.restoreFailed
        }
    }
}

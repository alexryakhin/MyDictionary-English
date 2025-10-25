//
//  PaywallService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI
import RevenueCat
import Combine

// MARK: - Paywall Service

@MainActor
final class PaywallService: ObservableObject {
    
    static let shared = PaywallService()
    
    // MARK: - Published Properties
    
    @Published var isShowingPaywall = false
    @Published var paywallPresentationReason: PaywallReason?
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    private let subscriptionService = SubscriptionService.shared
    private var paywallCompletionHandler: (BoolHandler)?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Presents the paywall when a user tries to access a Pro feature
    /// - Parameters:
    ///   - reason: The reason for showing the paywall
    ///   - completion: Called when the paywall is dismissed (true if user subscribed, false otherwise)
    func presentPaywall(for reason: PaywallReason, completion: @escaping BoolHandler = { _ in }) {
        // Don't show paywall if user is already Pro
        guard !subscriptionService.isProUser else {
            completion(true)
            return
        }
        
        paywallPresentationReason = reason
        paywallCompletionHandler = completion
        isShowingPaywall = true
        
        // Track analytics
        AnalyticsService.shared.logEvent(.paywallPresented)
    }
    
    /// Shows an alert requiring authentication before accessing Pro features
    private func showAuthenticationRequiredAlert(for reason: PaywallReason, completion: @escaping BoolHandler) {
        // Store completion handler for after authentication
        paywallCompletionHandler = completion
        paywallPresentationReason = reason
        
        // Show alert with sign-in options using cross-platform AlertCenter
        AlertCenter.shared.showAlert(
            with: .init(
                title: Loc.Subscription.Paywall.signInRequired,
                message: Loc.Auth.signInRequiredForProFeatures(reason.title),
                actionText: Loc.Actions.signIn,
                action: {
                    // Present sign-in options
                    self.presentSignInOptions()
                }
            )
        )
    }
    
    /// Presents sign-in options to the user
    private func presentSignInOptions() {
        #if os(iOS)
        // Use NavigationManager to present authentication view on iOS
        NavigationManager.shared.navigationPath.append(NavigationDestination.authentication)
        #else
        // On macOS, just show the paywall directly since authentication is handled differently
        // The MyPaywallView will handle showing AuthenticationView if needed
        isShowingPaywall = true
        #endif
        
        // Set up a listener for authentication state
        setupAuthenticationListener()
    }
    
    /// Sets up a listener to show paywall after successful authentication
    private func setupAuthenticationListener() {
        // Listen for authentication state changes
        AuthenticationService.shared.$authenticationState
            .sink { [weak self] state in
                if state == .signedIn {
                    // User signed in successfully, show paywall
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.showPaywallAfterAuthentication()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Shows the paywall after successful authentication
    private func showPaywallAfterAuthentication() {
        guard let reason = paywallPresentationReason else { return }
        
        isShowingPaywall = true
        
        // Track analytics
        AnalyticsService.shared.logEvent(.paywallPresented)
    }
    
    /// Dismisses the paywall
    func dismissPaywall() {
        isShowingPaywall = false
        paywallPresentationReason = nil
        
        // Call completion handler with false (user didn't subscribe)
        paywallCompletionHandler?(false)
        paywallCompletionHandler = nil
    }
    
    /// Called when user successfully completes a purchase
    /// This should ONLY be called when the purchase was actually successful
    func handlePurchaseCompleted() {
        isShowingPaywall = false
        paywallPresentationReason = nil

        // Call completion handler with true (user successfully subscribed)
        paywallCompletionHandler?(true)
        paywallCompletionHandler = nil
    }
    
    /// Called when user cancels or purchase fails
    /// This should be called when the purchase was cancelled, failed, or rejected
    func handlePurchaseFailed() {
        isShowingPaywall = false
        paywallPresentationReason = nil

        // Call completion handler with false (user didn't subscribe)
        paywallCompletionHandler?(false)
        paywallCompletionHandler = nil
    }
    
    /// Handles restore purchases with authentication check
    func handleRestorePurchases() async -> Bool {
        // Check if user is authenticated before restoring
        guard AuthenticationService.shared.isSignedIn else {
            showAuthenticationRequiredAlertForRestore()
            return false
        }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasActiveSubscription = !customerInfo.entitlements.active.isEmpty
            return hasActiveSubscription
        } catch {
            return false
        }
    }
    
    /// Shows authentication alert when user tries to restore purchases without being signed in
    private func showAuthenticationRequiredAlertForRestore() {
        AlertCenter.shared.showAlert(
            with: .init(
                title: Loc.Subscription.Paywall.signInRequired,
                message: Loc.Auth.signInRequiredForRestore,
                actionText: Loc.Actions.signIn,
                action: {
                    self.presentSignInOptions()
                }
            )
        )
    }
}

// MARK: - Paywall Reason

enum PaywallReason: String, CaseIterable {
    case googleSync = "google_sync"
    case unlimitedExport = "unlimited_export"
    case createSharedDictionaries = "create_shared_dictionaries"
    case advancedAnalytics = "advanced_analytics"
    case prioritySupport = "priority_support"
    case images = "images"
    case wordCollections = "word_collections"
    case general = "general"
    
    var title: String {
        switch self {
        case .googleSync:
            return Loc.Subscription.ProFeatures.googleSync
        case .unlimitedExport:
            return Loc.Subscription.ProFeatures.unlimitedExport
        case .createSharedDictionaries:
            return Loc.Subscription.ProFeatures.createSharedDictionaries
        case .advancedAnalytics:
            return Loc.Subscription.ProFeatures.advancedAnalytics
        case .prioritySupport:
            return Loc.Subscription.ProFeatures.prioritySupport
        case .images:
            return Loc.Subscription.ProFeatures.images
        case .wordCollections:
            return Loc.Subscription.ProFeatures.wordCollections
        case .general:
            return Loc.Subscription.ProFeatures.proFeatures
        }
    }
    
    var description: String {
        switch self {
        case .googleSync:
            return Loc.Subscription.ProFeatures.syncWordsAcrossDevices
        case .unlimitedExport:
            return Loc.Subscription.ProFeatures.exportUnlimitedWords
        case .createSharedDictionaries:
            return Loc.Subscription.ProFeatures.createManageSharedDictionaries
        case .advancedAnalytics:
            return Loc.Subscription.ProFeatures.detailedInsights
        case .prioritySupport:
            return Loc.Subscription.ProFeatures.prioritySupportTeam
        case .images:
            return Loc.Subscription.ProFeatures.imagesDescription
        case .wordCollections:
            return Loc.Subscription.ProFeatures.wordCollectionsDescription
        case .general:
            return Loc.Subscription.ProFeatures.unlockAllProFeatures
        }
    }
    
    var icon: String {
        switch self {
        case .googleSync:
            return "icloud.and.arrow.up"
        case .unlimitedExport:
            return "square.and.arrow.up"
        case .createSharedDictionaries:
            return "person.3"
        case .advancedAnalytics:
            return "chart.bar"
        case .prioritySupport:
            return "star"
        case .images:
            return "photo.fill"
        case .wordCollections:
            return "folder.fill"
        case .general:
            return "crown"
        }
    }
}

// MARK: - Paywall Modifier

struct MyPaywallView: View {
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        SimplifiedPaywallView()
    }
}

struct PaywallModifier: ViewModifier {
    
    @StateObject private var paywallService = PaywallService.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $paywallService.isShowingPaywall) {
                MyPaywallView()
        }
    }
}

extension View {
    func withPaywall() -> some View {
        modifier(PaywallModifier())
    }
}

// MARK: - Paywall Modifier

struct UpgradeToProModifier: ViewModifier {

    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared

    let message: String
    let font: Font

    func body(content: Content) -> some View {
        content
            .if(!subscriptionService.isProUser) { view in
                view
                    .blur(radius: 8, opaque: false)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "crown")
                                .foregroundStyle(.yellow)
                                .font(.title2)
                                .bold()
                            Text(message)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .font(font)
                        }
                        .onTap {
                            paywallService.isShowingPaywall = true
                        }
                    }
            }
    }
}

extension View {
    func reservedForPro(message: String, font: Font = .headline) -> some View {
        modifier(UpgradeToProModifier(message: message, font: font))
    }
}

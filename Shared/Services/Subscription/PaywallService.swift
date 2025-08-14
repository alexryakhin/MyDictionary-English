//
//  PaywallService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI
import RevenueCat
#if os(iOS)
import RevenueCatUI
#endif
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
        
        // Check if user is authenticated before showing paywall
        guard AuthenticationService.shared.isSignedIn else {
            print("⚠️ [PaywallService] User not authenticated - showing sign-in alert")
            showAuthenticationRequiredAlert(for: reason, completion: completion)
            return
        }
        
        paywallPresentationReason = reason
        paywallCompletionHandler = completion
        isShowingPaywall = true
        
        // Track analytics
        AnalyticsService.shared.logEvent(.paywallPresented)
        
        print("💰 [PaywallService] Presenting paywall for reason: \(reason)")
    }
    
    /// Shows an alert requiring authentication before accessing Pro features
    private func showAuthenticationRequiredAlert(for reason: PaywallReason, completion: @escaping BoolHandler) {
        // Store completion handler for after authentication
        paywallCompletionHandler = completion
        paywallPresentationReason = reason
        
        // Show alert with sign-in options using cross-platform AlertCenter
        AlertCenter.shared.showAlert(
            with: .init(
                title: "Sign In Required",
                message: "You need to sign in to access Pro features like \(reason.title).",
                actionText: "Sign In",
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
        
        print("✅ [PaywallService] User authenticated, showing paywall for: \(reason)")
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
        
        print("💰 [PaywallService] Paywall dismissed")
    }
    
    /// Called when user completes a purchase
    func handlePurchaseCompleted() {
        isShowingPaywall = false
        paywallPresentationReason = nil
        
        // Call completion handler with true (user subscribed)
        paywallCompletionHandler?(true)
        paywallCompletionHandler = nil
        
        print("💰 [PaywallService] Purchase completed, paywall dismissed")
    }
    
    /// Handles restore purchases with authentication check
    func handleRestorePurchases() async -> Bool {
        // Check if user is authenticated before restoring
        guard AuthenticationService.shared.isSignedIn else {
            print("⚠️ [PaywallService] Cannot restore purchases - user not authenticated")
            showAuthenticationRequiredAlertForRestore()
            return false
        }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasActiveSubscription = !customerInfo.entitlements.active.isEmpty
            
            if hasActiveSubscription {
                print("✅ [PaywallService] Purchases restored successfully")
                return true
            } else {
                print("ℹ️ [PaywallService] No active subscriptions found")
                return false
            }
        } catch {
            print("❌ [PaywallService] Failed to restore purchases: \(error)")
            return false
        }
    }
    
    /// Shows authentication alert when user tries to restore purchases without being signed in
    private func showAuthenticationRequiredAlertForRestore() {
        AlertCenter.shared.showAlert(
            with: .init(
                title: "Sign In Required",
                message: "You need to sign in to restore your purchases.",
                actionText: "Sign In",
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
    case general = "general"
    
    var title: String {
        switch self {
        case .googleSync:
            return "Google Sync"
        case .unlimitedExport:
            return "Unlimited Export"
        case .createSharedDictionaries:
            return "Create Shared Dictionaries"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .prioritySupport:
            return "Priority Support"
        case .general:
            return "Pro Features"
        }
    }
    
    var description: String {
        switch self {
        case .googleSync:
            return "Sync your words across all devices with Google Drive"
        case .unlimitedExport:
            return "Export unlimited words to CSV files"
        case .createSharedDictionaries:
            return "Create and manage shared dictionaries with others"
        case .advancedAnalytics:
            return "Get detailed insights into your learning progress"
        case .prioritySupport:
            return "Get priority support from our team"
        case .general:
            return "Unlock all Pro features"
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
        if authenticationService.isSignedIn {
            #if os(macOS)
            MacOSPaywall.ContentView()
            #else
            PaywallView()
            #endif
        } else {
            AuthenticationView(shownBeforePaywall: true)
        }
    }
}



struct PaywallModifier: ViewModifier {
    
    @StateObject private var paywallService = PaywallService.shared
    
    func body(content: Content) -> some View {
        content.sheet(isPresented: $paywallService.isShowingPaywall) {
            MyPaywallView()
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                #endif
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

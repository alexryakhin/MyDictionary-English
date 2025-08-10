//
//  PaywallService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import SwiftUI
import RevenueCat
import RevenueCatUI

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
    private var paywallCompletionHandler: ((Bool) -> Void)?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Presents the paywall when a user tries to access a Pro feature
    /// - Parameters:
    ///   - reason: The reason for showing the paywall
    ///   - completion: Called when the paywall is dismissed (true if user subscribed, false otherwise)
    func presentPaywall(for reason: PaywallReason, completion: @escaping (Bool) -> Void = { _ in }) {
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
        
        print("💰 [PaywallService] Presenting paywall for reason: \(reason)")
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

struct PaywallModifier: ViewModifier {
    
    @StateObject private var paywallService = PaywallService.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $paywallService.isShowingPaywall) {
                PaywallView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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

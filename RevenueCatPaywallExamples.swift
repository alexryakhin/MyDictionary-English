//
//  RevenueCatPaywallExamples.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
//  Examples of different ways to use RevenueCat's PaywallView
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Example 1: Simple PaywallView in Sheet

struct SimplePaywallExample: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Upgrade to Pro") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            RevenueCatUI.PaywallView()
        }
    }
}

// MARK: - Example 2: Using presentPaywallIfNeeded with Entitlement

struct EntitlementPaywallExample: View {
    var body: some View {
        Button("Access Google Sync") {
            Purchases.shared.presentPaywallIfNeeded(for: "google_sync") { customerInfo in
                if customerInfo.entitlements["google_sync"]?.isActive == true {
                    print("User has Google Sync access!")
                    // Proceed with Google sync
                } else {
                    print("User dismissed paywall or doesn't have access")
                }
            }
        }
    }
}

// MARK: - Example 3: Using PaywallService with Custom Logic

struct CustomLogicPaywallExample: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        Button("Export Unlimited Words") {
            paywallService.presentPaywall(for: .unlimitedExport) { didSubscribe in
                if didSubscribe {
                    print("User subscribed, can now export unlimited words")
                    // Proceed with export
                } else {
                    print("User dismissed paywall")
                }
            }
        }
    }
}

// MARK: - Example 4: Using PaywallService's presentPaywallIfNeeded

struct PaywallServiceExample: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        Button("Create Shared Dictionary") {
            paywallService.presentPaywallIfNeeded(
                for: "shared_dictionaries",
                reason: .createSharedDictionaries
            ) { hasAccess in
                if hasAccess {
                    print("User has access to create shared dictionaries")
                    // Proceed with dictionary creation
                } else {
                    print("User doesn't have access")
                }
            }
        }
    }
}

// MARK: - Example 5: Custom PaywallView with RevenueCat Data

struct CustomPaywallWithRevenueCatData: View {
    @State private var offerings: Offerings?
    @State private var customerInfo: CustomerInfo?
    
    var body: some View {
        VStack {
            if let offerings = offerings {
                RevenueCatUI.PaywallView(
                    offering: offerings.current,
                    customerInfo: customerInfo
                )
            } else {
                ProgressView("Loading paywall...")
            }
        }
        .task {
            do {
                offerings = try await Purchases.shared.offerings()
                customerInfo = try await Purchases.shared.customerInfo()
            } catch {
                print("Failed to load paywall data: \(error)")
            }
        }
    }
}

// MARK: - Example 6: Paywall with Custom Configuration

struct ConfiguredPaywallExample: View {
    @State private var showPaywall = false
    
    var body: some View {
        Button("Show Configured Paywall") {
            showPaywall = true
        }
        .sheet(isPresented: $showPaywall) {
            RevenueCatUI.PaywallView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Example 7: Conditional Paywall Presentation

struct ConditionalPaywallExample: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        Button("Access Pro Feature") {
            if subscriptionService.isProUser {
                // User is Pro, proceed immediately
                accessProFeature()
            } else {
                // Show paywall for free users
                paywallService.presentPaywall(for: .general) { didSubscribe in
                    if didSubscribe {
                        accessProFeature()
                    }
                }
            }
        }
    }
    
    private func accessProFeature() {
        print("Accessing Pro feature...")
    }
}

// MARK: - Example 8: Paywall with Analytics

struct AnalyticsPaywallExample: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        Button("Upgrade with Analytics") {
            // Track the event that led to paywall
            AnalyticsService.shared.logEvent(.paywallPresented(reason: .advancedAnalytics))
            
            paywallService.presentPaywall(for: .advancedAnalytics) { didSubscribe in
                if didSubscribe {
                    AnalyticsService.shared.logEvent(.subscriptionPurchased(plan: .monthly))
                    print("User subscribed to access advanced analytics")
                } else {
                    print("User dismissed analytics paywall")
                }
            }
        }
    }
}

// MARK: - Example 9: Paywall in Navigation

struct NavigationPaywallExample: View {
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Main Content")
                
                Button("Upgrade to Pro") {
                    showPaywall = true
                }
            }
            .navigationTitle("My App")
            .sheet(isPresented: $showPaywall) {
                NavigationView {
                    RevenueCatUI.PaywallView()
                        .navigationTitle("Upgrade to Pro")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Close") {
                                    showPaywall = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Example 10: Paywall with Error Handling

struct ErrorHandlingPaywallExample: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        Button("Upgrade with Error Handling") {
            Task {
                do {
                    // Check if user can purchase
                    let customerInfo = try await Purchases.shared.customerInfo()
                    
                    if customerInfo.entitlements["pro_access"]?.isActive == true {
                        print("User already has Pro access")
                        return
                    }
                    
                    // Show paywall
                    paywallService.presentPaywall(for: .general) { didSubscribe in
                        if didSubscribe {
                            print("Purchase successful")
                        } else {
                            print("Purchase cancelled or failed")
                        }
                    }
                } catch {
                    print("Error checking subscription status: \(error)")
                    // Handle error appropriately
                }
            }
        }
    }
}

// MARK: - Usage Notes

/*
 
 REVENUECAT PAYWALL INTEGRATION EXAMPLES
 
 This file demonstrates different ways to integrate RevenueCat's PaywallView
 into your My Dictionary app.
 
 Key Points:
 
 1. **RevenueCatUI.PaywallView()** - Use this for the simplest integration
 2. **presentPaywallIfNeeded** - Use for entitlement-based paywall presentation
 3. **PaywallService** - Use for custom logic and analytics tracking
 4. **Sheet Presentation** - Standard way to present paywall modally
 5. **Error Handling** - Always handle potential errors gracefully
 
 Best Practices:
 
 - Always check subscription status before showing paywall
 - Track analytics events for paywall presentations and purchases
 - Provide clear value proposition for Pro features
 - Handle both success and failure cases
 - Use appropriate paywall reasons for better conversion
 
 Configuration Required:
 
 1. Set up paywall in RevenueCat dashboard
 2. Configure entitlements for your Pro features
 3. Link products to entitlements
 4. Test with sandbox Apple IDs
 
 */

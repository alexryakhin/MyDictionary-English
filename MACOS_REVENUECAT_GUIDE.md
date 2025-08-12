# RevenueCat for macOS - Complete Implementation Guide

## Overview

This guide explains how to use RevenueCat for your macOS app, specifically addressing the limitation that `RevenueCatUI.PaywallView()` is not available on macOS and providing a complete solution.

## Key Limitations

### RevenueCatUI.PaywallView Limitation
```swift
// This is NOT available on macOS:
#if !os(macOS) && !os(tvOS)
PaywallView() // Only available on iOS
#endif
```

## Solution: Custom macOS Paywall

### 1. Custom MacOSPaywallView

We've created a native macOS paywall view that provides the same functionality as RevenueCatUI.PaywallView:

```swift
// My Dictionary (macOS)/UserInterface (macOS)/Settings/MacOSPaywallView.swift
struct MacOSPaywallView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            ScrollView {
                VStack(spacing: 32) {
                    featuresSection
                    subscriptionPlansSection
                    actionButtonsSection
                }
                .padding(32)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .background(Color(.windowBackgroundColor))
    }
}
```

### 2. Platform-Specific Paywall Presentation

The `MyPaywallView` automatically chooses the correct implementation:

```swift
struct MyPaywallView: View {
    @StateObject private var authenticationService = AuthenticationService.shared
    
    var body: some View {
        if authenticationService.isSignedIn {
            #if os(macOS)
            MacOSPaywallView() // Custom macOS implementation
            #else
            PaywallView() // RevenueCatUI for iOS
            #endif
        } else {
            AuthenticationView(shownBeforePaywall: true)
        }
    }
}
```

## How to Use RevenueCat on macOS

### 1. **Initialize RevenueCat**

Your app already has this set up in `SubscriptionService.swift`:

```swift
private func setupRevenueCat() {
    let configuration = Configuration.Builder(withAPIKey: AppConfig.RevenueCat.publicSDKKey)
        .with(storeKitVersion: .storeKit2)
        .build()
    
    Purchases.configure(with: configuration)
    Purchases.shared.delegate = self
}
```

### 2. **Present Paywall**

Use the `PaywallService` to present paywalls:

```swift
// Show paywall when user tries to access Pro features
PaywallService.shared.presentPaywall(for: .unlimitedExport) { didSubscribe in
    if didSubscribe {
        // User subscribed, enable Pro features
        print("User subscribed to Pro!")
    } else {
        // User didn't subscribe, show limited functionality
        print("User didn't subscribe")
    }
}
```

### 3. **Check Subscription Status**

```swift
let subscriptionService = SubscriptionService.shared

if subscriptionService.isProUser {
    // User has active Pro subscription
    print("User is Pro: \(subscriptionService.currentPlan?.displayName ?? "Unknown")")
} else {
    // User is on free plan
    print("User is on free plan")
}
```

### 4. **Purchase Subscriptions**

```swift
// Purchase a specific plan
Task {
    do {
        try await subscriptionService.purchasePlan(.yearly)
        // Handle successful purchase
    } catch {
        // Handle purchase error
    }
}
```

### 5. **Restore Purchases**

```swift
Task {
    do {
        try await subscriptionService.restorePurchases()
        // Handle success
    } catch {
        // Handle error
    }
}
```

## macOS-Specific Features

### 1. **Window Management**

The custom macOS paywall is designed for desktop:

```swift
.frame(minWidth: 600, minHeight: 700)
.background(Color(.windowBackgroundColor))
```

### 2. **Native macOS UI Elements**

Uses macOS-specific colors and styling:

```swift
.background(Color(.controlBackgroundColor))
.background(Color(.windowBackgroundColor))
```

### 3. **Menu Integration**

Add subscription options to your macOS menu:

```swift
Menu("Subscription") {
    Button("Manage Subscription") {
        // Open subscription management
    }
    
    Button("Restore Purchases") {
        Task {
            try? await SubscriptionService.shared.restorePurchases()
        }
    }
    
    if SubscriptionService.shared.isProUser {
        Button("View Pro Features") {
            // Show pro features
        }
    } else {
        Button("Upgrade to Pro") {
            PaywallService.shared.presentPaywall(for: .general)
        }
    }
}
```

## Feature Restrictions

### 1. **Export Limits**

```swift
// Check if user can export words
let canExport = SubscriptionService.shared.canExportWords(wordCount)
let exportLimit = SubscriptionService.shared.getExportLimit()

if !canExport {
    PaywallService.shared.presentPaywall(for: .unlimitedExport)
}
```

### 2. **Pro Feature Access**

```swift
// Use the reservedForPro modifier
VStack {
    // Pro feature content
}
.reservedForPro(message: "Upgrade to Pro to create shared dictionaries")
```

### 3. **Manual Feature Checks**

```swift
if SubscriptionService.shared.isProUser {
    // Enable Google Sync
    // Allow unlimited exports
    // Enable shared dictionary creation
} else {
    // Show limited functionality
    // Present upgrade prompts
}
```

## Testing on macOS

### 1. **Sandbox Testing**

1. Create sandbox Apple IDs in App Store Connect
2. Test with sandbox accounts in your macOS app
3. Verify subscription flow works correctly

### 2. **Debug Logging**

Your app already has debug logging enabled:

```swift
#if DEBUG
Purchases.logLevel = .debug
#endif
```

### 3. **Test Cases**

- [ ] Purchase monthly subscription
- [ ] Purchase yearly subscription  
- [ ] Restore purchases
- [ ] Test feature restrictions
- [ ] Verify cross-platform subscription sharing

## RevenueCat Dashboard Configuration

### 1. **Product Setup**

Ensure these products are configured in RevenueCat:
- `com.dor.mydictionary.pro.monthly` - Monthly Pro
- `com.dor.mydictionary.pro.yearly` - Yearly Pro

### 2. **Entitlements**

Configure entitlements for Pro features:
- `pro_monthly` and `pro_yearly` - Grant access to all Pro features

### 3. **Paywall Configuration**

Set up paywalls in RevenueCat dashboard for optimal conversion.

## Best Practices

### 1. **Authentication Integration**

Your setup handles authentication properly:
- Users must be signed in to access subscriptions
- Cross-platform App User ID ensures subscription sharing
- Automatic logout when user signs out

### 2. **Error Handling**

```swift
do {
    try await subscriptionService.purchasePlan(.monthly)
} catch SubscriptionError.noOfferingsAvailable {
    // Show appropriate error message
} catch SubscriptionError.purchaseFailed {
    // Handle purchase failure
} catch {
    // Handle other errors
}
```

### 3. **Analytics Integration**

Your app automatically tracks subscription events:
- `subscriptionScreenOpened`
- `subscriptionPurchased` 
- `subscriptionRestored`
- `subscriptionCancelled`

## Production Deployment

### 1. **App Store Connect**

1. Submit subscription products for review
2. Ensure subscription group is approved
3. Set up pricing and availability

### 2. **RevenueCat Production**

1. Switch to production API keys
2. Configure webhooks for server-side validation
3. Set up analytics and reporting

## Troubleshooting

### Common Issues

1. **Paywall not showing on macOS**
   - Ensure you're using `MacOSPaywallView()` instead of `PaywallView()`
   - Check that the paywall is being presented correctly

2. **Subscription not working**
   - Check API key configuration
   - Verify entitlements are properly set up
   - Test with sandbox accounts

3. **Feature restrictions not working**
   - Check `SubscriptionService.shared.isProUser` status
   - Verify error handling in restricted features

### Support

For RevenueCat-specific issues:
- [RevenueCat Documentation](https://docs.revenuecat.com/)
- [RevenueCat Support](https://www.revenuecat.com/support/)

For app-specific issues:
- Check console logs for error messages
- Verify subscription status in RevenueCat dashboard

## Summary

Your RevenueCat setup is now fully compatible with macOS! The key components are:

1. **Custom MacOSPaywallView** - Native macOS paywall implementation
2. **Platform-specific presentation** - Automatic selection of correct paywall
3. **Full RevenueCat integration** - All subscription features work on macOS
4. **Cross-platform subscription sharing** - Subscriptions work across iOS and macOS

The custom macOS paywall provides the same functionality as RevenueCatUI.PaywallView but is designed specifically for the desktop experience with proper window sizing, native macOS styling, and desktop-appropriate interactions.

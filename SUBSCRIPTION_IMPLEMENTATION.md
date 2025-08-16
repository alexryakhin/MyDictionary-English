# Subscription Implementation - Version 1.0

This document outlines the subscription implementation for the first version of My Dictionary app.

## Overview

The app uses **RevenueCat** for subscription management with **custom paywall designs** for both iOS and macOS.

## Architecture

### Components

1. **RevenueCat Integration** (`SubscriptionService.swift`)
   - **Dynamically loads products** from App Store Connect via RevenueCat
   - Manages purchases and restores
   - Tracks subscription status
   - Syncs across devices

2. **Custom Paywalls**
   - **iOS**: `CustomPaywallView.swift` - Clean, mobile-optimized design
   - **macOS**: `MacOSPaywallView.swift` - Desktop-optimized design
   - **Advanced**: `AdvancedPaywallView.swift` - Premium design with animations (future use)

3. **Paywall Service** (`PaywallService.swift`)
   - Manages paywall presentation
   - Handles authentication requirements
   - Tracks analytics events
   - Provides completion callbacks

## Subscription Plans

### Dynamic Product Loading
- **Products are loaded dynamically** from App Store Connect via RevenueCat
- **No hardcoded prices** - all pricing comes from App Store Connect
- **Automatic localization** - prices and descriptions are localized
- **Flexible configuration** - add/remove products without app updates

### Example Product IDs
- `com.dor.mydictionary.pro.monthly`
- `com.dor.mydictionary.pro.yearly`

### Pro Features
- **Unlimited Export**: Export unlimited words to CSV
- **Create Shared Dictionaries**: Create and manage shared dictionaries with collaborators
- **Advanced Analytics**: Detailed progress tracking and insights
- **Priority Support**: Get priority support when you need help

## Usage

### Basic Paywall Presentation
```swift
PaywallService.shared.presentPaywall(for: .createSharedDictionaries) { success in
    if success {
        print("User subscribed!")
        // Enable Pro features
    }
}
```

### Check Subscription Status
```swift
if SubscriptionService.shared.isProUser {
    // User has active subscription
    // Enable Pro features
}
```

### Feature Gating
```swift
// In your SwiftUI views
someView
    .reservedForPro("Create shared dictionaries to unlock this feature")
```

## Analytics

The system tracks:
- Paywall presentations
- Subscription conversions
- Feature-specific paywall triggers

## RevenueCat Setup

### Required Configuration
1. **Product IDs**:
   - `com.dor.mydictionary.pro.monthly`
   - `com.dor.mydictionary.pro.yearly`

2. **Entitlements**:
   - `pro_access` - Grants access to all Pro features

### App Store Connect
- Configure products in App Store Connect
- Set up subscription groups
- Configure pricing and availability

## Future Enhancements

When ready for A/B testing:
1. Re-add `PaywallABTestService.swift`
2. Re-add `PaywallDebugView.swift`
3. Enable variant switching in `PaywallService.swift`

## Testing

### Development Testing
- Use RevenueCat's sandbox environment
- Test with sandbox Apple IDs
- Verify subscription status updates

### Production Testing
- Test with real App Store accounts
- Verify receipt validation
- Test subscription renewal flows

## Support

For subscription issues:
1. Check RevenueCat dashboard for purchase status
2. Verify App Store Connect product configuration
3. Test with different Apple IDs and devices

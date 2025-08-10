# Paywall Integration Guide

## Overview

This guide explains how to integrate RevenueCat's PaywallView into your My Dictionary app to present subscription offers when users try to access Pro features.

## 🎯 **How It Works**

The paywall system uses RevenueCat's built-in `PaywallView` with a beautiful aurora background animation to present subscription offers when users try to access Pro features:

1. **User tries to access a Pro feature** (e.g., export more than 50 words)
2. **System checks subscription status** via `SubscriptionService`
3. **If not Pro user**: Custom PaywallView with aurora background is presented
4. **If Pro user**: Feature is granted immediately
5. **After purchase**: Paywall dismisses and feature becomes available

## 🌌 **Aurora Background Features**

The paywall includes a mesmerizing aurora background animation that:

- **Adapts to accessibility settings**: Respects reduced motion and transparency preferences
- **Supports dark/light mode**: Automatically adjusts colors for different schemes
- **Colorblind friendly**: Provides alternative backgrounds for accessibility
- **Smooth animations**: Floating clouds with organic movement patterns
- **Professional design**: Creates an engaging upgrade experience

## 🚀 **Quick Start**

### 1. **Paywall is Already Integrated**

The paywall system is already integrated into your main app views:

```swift
// iOS MainTabView
MainTabView()
    .withPaywall()

// macOS MainTabView  
MainTabView()
    .withPaywall()
```

### 2. **Automatic Feature Gating**

The following features automatically show the paywall when accessed by free users:

- **Google Sync**: When trying to sync to Google Drive
- **Unlimited Export**: When trying to export more than 50 words
- **Create Shared Dictionaries**: When trying to create a new shared dictionary

## 📋 **Usage Examples**

### **Manual Paywall Presentation**

You can manually present the paywall anywhere in your code:

```swift
import SwiftUI

struct MyView: View {
    @StateObject private var paywallService = PaywallService.shared
    
    var body: some View {
        Button("Upgrade to Pro") {
            paywallService.presentPaywall(
                for: .general,
                completion: { didSubscribe in
                    if didSubscribe {
                        print("User subscribed!")
                    } else {
                        print("User dismissed paywall")
                    }
                }
            )
        }
    }
}
```

### **Pro Feature Placeholders with Aurora Background**

Create beautiful placeholders for Pro features:

```swift
struct GoogleSyncView: View {
    var body: some View {
        ZStack {
            AuroraBackground()
            
            VStack {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                
                Text("Google Sync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Button("Upgrade to Pro") {
                    // Show paywall
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .preferredColorScheme(.dark)
    }
}
```

### **Feature-Specific Paywall**

Show paywall for specific features:

```swift
// For Google Sync
paywallService.presentPaywall(for: .googleSync) { didSubscribe in
    if didSubscribe {
        // Retry Google sync
        try? await dataSyncService.syncToGoogle()
    }
}

// For unlimited export
paywallService.presentPaywall(for: .unlimitedExport) { didSubscribe in
    if didSubscribe {
        // Retry export
        exportWords()
    }
}

// For shared dictionaries
paywallService.presentPaywall(for: .createSharedDictionaries) { didSubscribe in
    if didSubscribe {
        // Retry dictionary creation
        createSharedDictionary()
    }
}
```

### **Check Access Before Showing Paywall**

Use the convenience method to check access and show paywall if needed:

```swift
let paywallService = PaywallService.shared

// This will show paywall if user doesn't have access
let hasAccess = paywallService.checkAccessAndShowPaywallIfNeeded(
    for: .googleSync,
    reason: .googleSync
) { didSubscribe in
    if didSubscribe {
        // User now has access, proceed with feature
        performGoogleSync()
    }
}

if hasAccess {
    // User already has access, proceed immediately
    performGoogleSync()
}
```

## 🎨 **Paywall Reasons**

The system supports different paywall reasons with custom messaging:

```swift
enum PaywallReason {
    case googleSync           // "Sync your words across all devices with Google Drive"
    case unlimitedExport      // "Export unlimited words to CSV files"
    case createSharedDictionaries // "Create and manage shared dictionaries with others"
    case advancedAnalytics    // "Get detailed insights into your learning progress"
    case prioritySupport      // "Get priority support from our team"
    case general             // "Unlock all Pro features"
}
```

## 🔧 **Customization**

### **Using Custom PaywallView with Aurora Background**

The system uses a custom `PaywallView` that combines RevenueCat's functionality with a beautiful aurora background:

- **Aurora Animation**: Mesmerizing floating clouds with organic movement
- **RevenueCat Integration**: Full subscription management capabilities
- **Accessibility Support**: Respects user accessibility preferences
- **Professional Design**: Engaging upgrade experience

```swift
import SwiftUI
import RevenueCatUI

// Use the custom paywall with aurora background
CustomPaywallView()

// Or use the aurora background modifier
YourView()
    .auroraBackground()
```

### **Alternative Paywall Presentation Methods**

You can also use RevenueCat's other paywall presentation methods:

```swift
// Method 1: Using presentPaywallIfNeeded with entitlement
Purchases.shared.presentPaywallIfNeeded(for: "pro_access") { customerInfo in
    // Handle result
}

// Method 2: Using PaywallService's built-in method
PaywallService.shared.presentPaywallIfNeeded(
    for: "pro_access",
    reason: .googleSync
) { hasAccess in
    // Handle result
}

// Method 3: Manual presentation with custom logic
PaywallService.shared.presentPaywall(for: .unlimitedExport) { didSubscribe in
    // Handle result
}
```

## 📊 **Analytics**

The paywall system automatically tracks analytics events:

```swift
// Paywall presented
AnalyticsService.shared.logEvent(.paywallPresented(reason: .googleSync))

// Subscription purchased
AnalyticsService.shared.logEvent(.subscriptionPurchased(plan: .monthly))

// Subscription error
AnalyticsService.shared.logEvent(.subscriptionError(error: error))
```

## 🔒 **Security**

- **Public SDK Key**: Safe to include in app code
- **Secret API Key**: Only for server-side operations
- **Configuration**: Stored in `AppConfig.swift` (gitignored)

## ⚙️ **RevenueCat Dashboard Configuration**

To use RevenueCat's PaywallView, you need to configure your paywall in the RevenueCat dashboard:

### **1. Create Paywall**
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com/)
2. Navigate to **Paywalls** → **Create Paywall**
3. Design your paywall with RevenueCat's visual editor
4. Configure products, pricing, and messaging

### **2. Configure Entitlements**
1. Go to **Entitlements** → **Create Entitlement**
2. Create entitlements for your Pro features:
   - `pro_access` - General Pro access
   - `google_sync` - Google Drive sync
   - `unlimited_export` - Unlimited CSV export
   - `shared_dictionaries` - Create shared dictionaries

### **3. Link Products to Entitlements**
1. Go to **Products** → **Link to Entitlements**
2. Link your subscription products to the appropriate entitlements
3. Set up subscription groups and pricing

### **4. Configure Paywall Display**
1. In your paywall settings, configure when to show the paywall
2. Set up A/B tests for different paywall designs
3. Configure localization for different languages

## 🧪 **Testing**

### **Sandbox Testing**

1. Create sandbox Apple IDs in App Store Connect
2. Test subscription flow with sandbox accounts
3. Verify paywall appears for free users
4. Test feature access after subscription

### **Test Cases**

```swift
// Test paywall presentation
paywallService.presentPaywall(for: .googleSync) { didSubscribe in
    print("Paywall result: \(didSubscribe)")
}

// Test access checking
let hasAccess = paywallService.checkAccessAndShowPaywallIfNeeded(
    for: .unlimitedExport,
    reason: .unlimitedExport
) { didSubscribe in
    print("Access granted: \(didSubscribe)")
}
```

## 🐛 **Troubleshooting**

### **Paywall Not Showing**

1. Check if user is already Pro:
   ```swift
   if SubscriptionService.shared.isProUser {
       // User is Pro, no paywall needed
   }
   ```

2. Verify paywall service is initialized:
   ```swift
   let paywallService = PaywallService.shared
   ```

3. Check RevenueCat configuration:
   ```swift
   // In AppConfig.swift
   static let publicSDKKey = "appl_YOUR_ACTUAL_KEY"
   ```

### **Paywall Not Dismissing**

1. Check subscription status updates:
   ```swift
   @StateObject private var subscriptionService = SubscriptionService.shared
   ```

2. Verify purchase completion handling:
   ```swift
   paywallService.handlePurchaseCompleted()
   ```

## 📱 **Platform Support**

- **iOS**: Full support with sheet presentation
- **macOS**: Full support with sheet presentation
- **Cross-platform**: Shared paywall logic

## 🎯 **Best Practices**

1. **Contextual Messaging**: Use specific paywall reasons for better conversion
2. **Graceful Degradation**: Always provide fallback for free users
3. **Clear Value Proposition**: Explain benefits clearly in paywall
4. **Easy Dismissal**: Allow users to dismiss paywall easily
5. **Retry Logic**: Automatically retry actions after subscription

## 📞 **Support**

For issues with the paywall system:
- Check console logs for error messages
- Verify RevenueCat dashboard configuration
- Test with sandbox accounts
- Review subscription status in RevenueCat dashboard

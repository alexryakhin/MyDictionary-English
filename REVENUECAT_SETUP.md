# RevenueCat Integration Setup Guide

## Overview

This guide will help you set up RevenueCat for cross-platform subscription management in your My Dictionary app. The implementation includes:

- **Monthly Pro**: $4.99/month
- **Yearly Pro**: $39.99/year (33% savings)
- Feature restrictions for free users
- Cross-platform subscription management

## Prerequisites

1. RevenueCat account
2. App Store Connect access
3. Xcode project with StoreKit 2 support

## Step 1: RevenueCat Dashboard Setup

### 1.1 Create Project
1. Log into [RevenueCat Dashboard](https://app.revenuecat.com/)
2. Create a new project
3. Add your app bundle ID: `com.dor.My-Dictionary`

### 1.2 Configure Products
Create the following products in RevenueCat:

#### Monthly Pro Subscription
- **Product ID**: `com.dor.mydictionary.pro.monthly`
- **Type**: Auto-Renewable Subscription
- **Price**: $4.99/month
- **Entitlement**: `pro_monthly`

#### Yearly Pro Subscription
- **Product ID**: `com.dor.mydictionary.pro.yearly`
- **Type**: Auto-Renewable Subscription
- **Price**: $39.99/year
- **Entitlement**: `pro_yearly`

### 1.3 Configure Entitlements
Create entitlements that grant access to Pro features:

- **Entitlement**: `pro_monthly` and `pro_yearly`
- **Features**:
  - Google Sync
  - Unlimited Export
  - Create Shared Dictionaries
  - Advanced Analytics
  - Priority Support

## Step 2: App Store Connect Setup

### 2.1 Create Subscription Group
1. Go to App Store Connect > Your App > Features > In-App Purchases
2. Create a new subscription group: "Pro Subscription"
3. Add both monthly and yearly products

### 2.2 Configure Products
Create the same products as in RevenueCat:

#### Monthly Pro
- Product ID: `com.dor.mydictionary.pro.monthly`
- Reference Name: "Monthly Pro"
- Subscription Group: "Pro Subscription"
- Price: $4.99/month

#### Yearly Pro
- Product ID: `com.dor.mydictionary.pro.yearly`
- Reference Name: "Yearly Pro"
- Subscription Group: "Pro Subscription"
- Price: $39.99/year

### 2.3 Set Up Subscription Levels
1. Create subscription level "Pro"
2. Add both products to this level
3. Configure availability and pricing

## Step 3: Code Implementation

### 3.1 Add RevenueCat Dependency
The project already includes RevenueCat as a dependency. If you need to add it manually:

```swift
// In Package.swift
.package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "4.0.0")
```

### 3.2 Update API Keys

#### Step 1: Get Your API Keys
1. Go to [RevenueCat Dashboard](https://app.revenuecat.com/)
2. Select your project
3. Go to **Project Settings** → **API Keys**
4. Copy your **Public SDK Key** (starts with `appl_`)

#### Step 2: Configure Your App
1. Copy `Shared/Config/AppConfig.template.swift` to `Shared/Config/AppConfig.swift`
2. Replace the placeholder values with your actual API keys:

```swift
struct RevenueCat {
    static let publicSDKKey = "appl_YOUR_ACTUAL_PUBLIC_SDK_KEY"
    static let secretAPIKey = "sk_YOUR_ACTUAL_SECRET_API_KEY"
}
```

**Important Security Notes:**
- The **Public SDK Key** is safe to include in your app code
- The **Secret API Key** should only be used for server-side operations
- Never commit `AppConfig.swift` to version control (it's already in `.gitignore`)

### 3.3 Verify Implementation
The following files have been created/modified:

- `Shared/Services/SubscriptionService.swift` - Core subscription logic
- `My Dictionary/UserInterface/Home/Settings/SubscriptionView.swift` - iOS subscription UI
- `My Dictionary (macOS)/UserInterface (macOS)/Settings/SubscriptionView.swift` - macOS subscription UI
- `My Dictionary/UserInterface/Home/Settings/SubscriptionStatusView.swift` - iOS status view
- `My Dictionary (macOS)/UserInterface (macOS)/Settings/SubscriptionStatusView.swift` - macOS status view

## Step 4: Feature Restrictions Implementation

### 4.1 Export Limits
- **Free users**: 50 words maximum
- **Pro users**: Unlimited export
- Implementation: `CSVManager.swift` and `SettingsViewModel.swift`

### 4.2 Google Sync
- **Free users**: iCloud sync only
- **Pro users**: Google sync enabled
- Implementation: `DataSyncService.swift` and `AuthenticationService.swift`

### 4.3 Shared Dictionaries
- **Free users**: Can only be editor/viewer
- **Pro users**: Can create and own dictionaries
- Implementation: `DictionaryService.swift`

### 4.4 Analytics
- **Free users**: Basic analytics
- **Pro users**: Advanced analytics
- Implementation: `AnalyticsService.swift`

## Step 5: Testing

### 5.1 Sandbox Testing
1. Create sandbox Apple IDs in App Store Connect
2. Test subscription flow with sandbox accounts
3. Verify feature restrictions work correctly
4. Test restore purchases functionality

### 5.2 Test Cases
- [ ] Purchase monthly subscription
- [ ] Purchase yearly subscription
- [ ] Restore purchases
- [ ] Export limit enforcement (free users)
- [ ] Google sync restriction (free users)
- [ ] Shared dictionary creation restriction (free users)
- [ ] Subscription expiration handling

## Step 6: Production Deployment

### 6.1 App Store Connect
1. Submit products for review
2. Ensure subscription group is approved
3. Set up pricing and availability

### 6.2 RevenueCat
1. Switch to production API key
2. Configure webhooks for server-side validation
3. Set up analytics and reporting

### 6.3 App Store Review
1. Ensure subscription flow works correctly
2. Provide clear upgrade messaging
3. Include restore purchases functionality
4. Test with App Review team

## Feature Matrix

| Feature | Free | Pro |
|---------|------|-----|
| iCloud Sync | ✅ | ✅ |
| Google Sync | ❌ | ✅ |
| Export Words | 50 max | Unlimited |
| Import Words | ✅ | ✅ |
| Create Shared Dictionaries | ❌ | ✅ |
| Join Shared Dictionaries | ✅ | ✅ |
| Basic Analytics | ✅ | ✅ |
| Advanced Analytics | ❌ | ✅ |
| Priority Support | ❌ | ✅ |

## Troubleshooting

### Common Issues

1. **Products not found**
   - Verify product IDs match between App Store Connect and RevenueCat
   - Ensure products are approved and active

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

## Analytics Events

The app automatically tracks these subscription events:
- `subscriptionScreenOpened`
- `subscriptionPurchased`
- `subscriptionRestored`
- `subscriptionCancelled`

These events are sent to your analytics service for tracking conversion rates and user behavior.

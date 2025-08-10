# RevenueCat Configuration Guide

## Setup Instructions

### 1. RevenueCat Dashboard Setup

1. Create a new project in RevenueCat dashboard
2. Add your app bundle ID: `com.dor.My-Dictionary`
3. Configure the following products:

#### Products Configuration

**Monthly Pro Subscription**
- Product ID: `com.dor.mydictionary.pro.monthly`
- Type: Auto-Renewable Subscription
- Price: $4.99/month
- Entitlement: `pro_monthly`

**Yearly Pro Subscription**
- Product ID: `com.dor.mydictionary.pro.yearly`
- Type: Auto-Renewable Subscription
- Price: $39.99/year
- Entitlement: `pro_yearly`

### 2. App Store Connect Setup

1. Create the same products in App Store Connect
2. Set up subscription groups
3. Configure pricing and availability

### 3. Code Configuration

Update the API key in `SubscriptionService.swift`:

```swift
Purchases.configure(
    with: Configuration.Builder(withAPIKey: "YOUR_ACTUAL_API_KEY")
        .with(usesStoreKit2IfAvailable: true)
        .build()
)
```

### 4. Entitlements Configuration

In RevenueCat dashboard, create the following entitlements:

- `pro_monthly` - Monthly Pro features
- `pro_yearly` - Yearly Pro features

Both entitlements should grant access to:
- Google Sync
- Unlimited Export
- Create Shared Dictionaries
- Advanced Analytics
- Priority Support

### 5. Testing

Use RevenueCat's sandbox environment for testing:
- Test with sandbox Apple IDs
- Verify subscription flow
- Test restore purchases
- Test subscription expiration

### 6. Analytics Events

The app automatically tracks these subscription events:
- `subscriptionScreenOpened`
- `subscriptionPurchased`
- `subscriptionRestored`
- `subscriptionCancelled`

## Feature Restrictions

### Free Users
- iCloud sync only
- 50 word export limit
- Can only be editor/viewer in shared dictionaries
- Basic analytics

### Pro Users
- Google sync enabled
- Unlimited word export
- Can create shared dictionaries (owner role)
- Advanced analytics
- Priority support

## Implementation Notes

1. The subscription service checks feature access before allowing restricted operations
2. Export limits are enforced in CSVManager
3. Google sync requires Pro subscription
4. Shared dictionary creation requires Pro subscription
5. Analytics features are enhanced for Pro users

## Troubleshooting

- Ensure RevenueCat API key is correct
- Verify product IDs match between App Store Connect and RevenueCat
- Check entitlements are properly configured
- Test with sandbox accounts before production

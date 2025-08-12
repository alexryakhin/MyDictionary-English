# Android RevenueCat Setup Guide

## Overview
This guide explains how to set up RevenueCat on Android to enable cross-platform subscription sharing with iOS.

## 1. Add RevenueCat Dependencies

Add to your `app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.revenuecat.purchases:purchases:6.0.0")
    implementation("com.revenuecat.purchases:purchases-ui:6.0.0")
}
```

## 2. Initialize RevenueCat

In your `Application` class or main activity:

```kotlin
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration

class MyDictionaryApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize RevenueCat
        val configuration = PurchasesConfiguration.Builder(this, "your_revenuecat_api_key")
            .build()
        Purchases.configure(configuration)
    }
}
```

## 3. Set Up Cross-Platform App User ID

Create a `SubscriptionService.kt`:

```kotlin
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.CustomerInfo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class SubscriptionService {
    companion object {
        private const val TAG = "SubscriptionService"
    }
    
    private var isProUser: Boolean = false
    private var currentPlan: String? = null
    
    /**
     * Sets up the App User ID for cross-platform subscription sharing
     * Uses email as the App User ID to match iOS implementation
     */
    suspend fun setupAppUserID(userEmail: String) {
        withContext(Dispatchers.IO) {
            try {
                val customerInfo = Purchases.sharedInstance.logIn(userEmail)
                Log.d(TAG, "App User ID set successfully: $userEmail")
                Log.d(TAG, "Customer info: ${customerInfo.originalAppUserId}")
                
                // Update subscription status
                updateSubscriptionStatus(customerInfo)
                
                // Sync to Firestore
                syncSubscriptionStatusToFirestore(userEmail, customerInfo)
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to set App User ID: ${e.message}")
            }
        }
    }
    
    private fun updateSubscriptionStatus(customerInfo: CustomerInfo) {
        isProUser = customerInfo.entitlements.active.isNotEmpty()
        currentPlan = customerInfo.entitlements.active.values.firstOrNull()?.identifier
        
        Log.d(TAG, "Subscription status updated - isPro: $isProUser, plan: $currentPlan")
    }
    
    private suspend fun syncSubscriptionStatusToFirestore(userEmail: String, customerInfo: CustomerInfo) {
        withContext(Dispatchers.IO) {
            try {
                val db = FirebaseFirestore.getInstance()
                val expiryDate = customerInfo.entitlements.active.values.firstOrNull()?.expirationDate
                
                val subscriptionData = hashMapOf(
                    "subscriptionStatus" to if (isProUser) "pro" else "free",
                    "subscriptionPlan" to currentPlan,
                    "subscriptionExpiryDate" to expiryDate,
                    "lastUpdated" to FieldValue.serverTimestamp()
                )
                
                db.collection("users").document(userEmail)
                    .update(subscriptionData)
                    .await()
                
                Log.d(TAG, "Subscription status synced to Firestore")
                
            } catch (e: Exception) {
                Log.e(TAG, "Failed to sync subscription status: ${e.message}")
            }
        }
    }
    
    fun isProUser(): Boolean = isProUser
    
    fun getCurrentPlan(): String? = currentPlan
    
    fun getSharedDictionaryLimit(): Int = if (isProUser) Int.MAX_VALUE else 1
    
    fun canCreateMoreSharedDictionaries(currentCount: Int): Boolean {
        return currentCount < getSharedDictionaryLimit()
    }
}
```

## 4. User Document Structure

Your Firestore user documents should have this structure:

```json
{
  "fcmToken": "token_string",
  "userId": "firebase_uid",
  "email": "user@example.com",
  "name": "User Display Name",
  "registrationDate": "timestamp",
  "lastUpdated": "timestamp",
  "platform": "Android",
  "subscriptionStatus": "pro", // or "free"
  "subscriptionPlan": "pro_monthly", // or "pro_yearly"
  "subscriptionExpiryDate": "timestamp"
}
```

## 5. Call Setup on User Sign-In

In your authentication flow:

```kotlin
// After successful Firebase authentication
val userEmail = FirebaseAuth.getInstance().currentUser?.email
if (userEmail != null) {
    subscriptionService.setupAppUserID(userEmail)
}
```

## 6. Check Subscription Status

```kotlin
// Check if user can create shared dictionaries
if (subscriptionService.canCreateMoreSharedDictionaries(currentDictionaryCount)) {
    // Allow creation
} else {
    // Show upgrade prompt
}

// Check if user has Pro features
if (subscriptionService.isProUser()) {
    // Enable Pro features
}
```

## 7. RevenueCat Dashboard Configuration

1. **Create App User ID**: In RevenueCat dashboard, ensure both iOS and Android apps use the same App User ID (email)
2. **Product Configuration**: Set up the same product IDs for both platforms:
   - `com.dor.mydictionary.pro.monthly`
   - `com.dor.mydictionary.pro.yearly`
3. **Entitlements**: Configure the same entitlements for both platforms

## 8. Testing Cross-Platform Sharing

1. **Purchase on iOS**: Subscribe to Pro on iOS
2. **Check Android**: Sign in with same email on Android - subscription should be active
3. **Purchase on Android**: Subscribe to Pro on Android
4. **Check iOS**: Sign in with same email on iOS - subscription should be active

## 9. Debugging

Add logging to track subscription status:

```kotlin
Purchases.sharedInstance.getCustomerInfo { error, customerInfo ->
    if (error != null) {
        Log.e(TAG, "Error getting customer info: ${error.message}")
    } else {
        Log.d(TAG, "Customer info: ${customerInfo?.entitlements}")
    }
}
```

## 10. Firebase Functions Integration

Your existing Firebase Functions will work with Android users since they use the same user document structure. The push notification system will automatically work for Android users who have FCM tokens stored in their user documents.

## Key Points

- ✅ **Use email as App User ID** for cross-platform consistency
- ✅ **Sync subscription status to Firestore** for server-side access
- ✅ **Same product IDs** across platforms
- ✅ **Same user document structure** as iOS
- ✅ **Automatic subscription sharing** through RevenueCat

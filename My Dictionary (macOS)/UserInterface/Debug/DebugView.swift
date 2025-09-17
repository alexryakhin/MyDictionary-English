//
//  DebugView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
// DO NOT TRANSLATE DEBUG
#if DEBUG
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseMessaging

struct DebugView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var dictionaryService = DictionaryService.shared
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var featureToggleService = FeatureToggleService.shared

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var fcmToken = "Loading..."
    @State private var userEmail = "Not signed in"
    @State private var userId = "Not signed in"
    @State private var testNotificationEmail = ""
    @State private var showingEmailInput = false

    var body: some View {
        List {
            userInfoSection
            featureToggleSection
            pushNotificationsSection
            subscriptionTestingSection
            dictionaryTestingSection
            firebaseTestingSection
            appTestingSection
        }
        .navigationTitle("Debug Panel")
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                HeaderButton("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadUserInfo()
        }
        .alert("Debug Info", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Send Test Notification", isPresented: $showingEmailInput) {
            TextField("Enter email address", text: $testNotificationEmail)
                .autocorrectionDisabled()
                .textFieldStyle(.plain)
           Button(Loc.Actions.cancel, role: .cancel) {
                testNotificationEmail = ""
            }
        } message: {
            Text("Enter the email address of the user you want to send a test notification to.")
        }
    }

    // MARK: - View Sections

    private var userInfoSection: some View {
        Section("User Information") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Email:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(userEmail)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("User ID:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(userId)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("Auth State:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(authenticationService.authenticationState)")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Pro User:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(subscriptionService.isProUser ? "Yes" : "No")
                        .foregroundStyle(subscriptionService.isProUser ? .accent : .red)
                }
            }
        }
    }

    private var featureToggleSection: some View {
        Section("Feature Toggles") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(FeatureToggleItem.allCases, id: \.rawValue) { feature in
                    HStack {
                        Text(feature.rawValue)
                            .fontWeight(.medium)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { featureToggleService.isEnabled(feature) },
                            set: { newValue in
                                // Update the local dictionary for immediate UI feedback
                                featureToggleService.featureToggles[feature] = newValue
                                showAlert("\(feature.rawValue) \(newValue ? "enabled" : "disabled") locally")
                            }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 2)
                }
                
                HeaderButton("Refresh from Firebase") {
                    Task {
                        await featureToggleService.fetchFeatureToggles()
                        showAlert("Feature toggles refreshed from Firebase")
                    }
                }
                
                HeaderButton("Force Refresh (Bypass Cache)") {
                    Task {
                        await featureToggleService.forceRefresh()
                        showAlert("Feature toggles force refreshed from Firebase")
                    }
                }
            }
        }
    }

    private var pushNotificationsSection: some View {
        Section("Push Notifications") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("FCM Token:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(fcmToken.prefix(20) + "...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                HeaderButton("Copy FCM Token") {
                    copyToClipboard(fcmToken)
                    showAlert("FCM Token copied to clipboard")
                }

                HeaderButton("Test Local Notification") {
                    testLocalNotification()
                }

                HeaderButton("Request Notification Permission") {
                    Task {
                        await authenticationService.requestPushNotificationPermissions()
                    }
                }

                HeaderButton("Check Notification Settings") {
                    checkNotificationSettings()
                }
            }
        }
    }

    private var subscriptionTestingSection: some View {
        Section("Subscription Testing") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Plan:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(subscriptionService.currentPlan?.id ?? "None")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Debug Premium Mode:")
                        .fontWeight(.medium)
                    Spacer()
                    Toggle("", isOn: $subscriptionService.debugPremiumMode)
                        .labelsHidden()
                        .onChange(of: subscriptionService.debugPremiumMode) { newValue in
                            if newValue {
                                showAlert("Debug Premium Mode Enabled - You are now a Pro user locally")
                            } else {
                                showAlert("Debug Premium Mode Disabled - Back to normal subscription status")
                            }
                        }
                }
                .padding(.vertical, 4)

                HeaderButton("Refresh Subscription Status") {
                    Task {
                        await subscriptionService.checkSubscriptionStatus()
                    }
                }

                HeaderButton("Sync Subscription to Firestore") {
                    Task {
                        await subscriptionService.syncSubscriptionStatus()
                        showAlert("Subscription status synced to Firestore")
                    }
                }

                HeaderButton("Verify Subscription Ownership") {
                    Task {
                        let isOwner = await subscriptionService.verifySubscriptionOwnership()
                        showAlert(isOwner ? "Subscription ownership verified ✅" : "Subscription ownership failed ❌")
                    }
                }

                HeaderButton("Test Paywall (Auth Check)") {
                    paywallService.presentPaywall(for: .createSharedDictionaries) { didSubscribe in
                        showAlert(didSubscribe ? "User subscribed! 🎉" : "User dismissed paywall")
                    }
                }

                HeaderButton("Test Complete Auth Flow") {
                    Task {
                        await subscriptionService.setupAppUserID()
                        showAlert("Auth flow successful! ✅")
                    }
                }

                HeaderButton("Test Immediate Sign Out") {
                    Task {
                        // First check current status
                        let wasPro = subscriptionService.isProUser

                        // Simulate sign out
                        subscriptionService.resetSubscriptionStatusOnSignOut()

                        let isProNow = subscriptionService.isProUser
                        showAlert("Before: \(wasPro ? "Pro" : "Free"), After: \(isProNow ? "Pro" : "Free")")
                    }
                }

                HeaderButton("Create User Document") {
                    Task {
                        if let user = authenticationService.currentUser {
                            await authenticationService.createUserDocument(user: user)
                            showAlert("User document creation attempted")
                        } else {
                            showAlert("No authenticated user")
                        }
                    }
                }

                HeaderButton("Check User Document") {
                    Task {
                        guard let userEmail = authenticationService.userEmail else {
                            showAlert("No user email available")
                            return
                        }

                        do {
                            let db = Firestore.firestore()
                            let doc = try await db.collection("users").document(userEmail).getDocument()

                            if doc.exists {
                                let data = doc.data() ?? [:]
                                let fields = data.keys.sorted().joined(separator: ", ")
                                showAlert("Document exists with fields: \(fields)")
                            } else {
                                showAlert("Document does not exist")
                            }
                        } catch {
                            showAlert("Error checking document: \(error.localizedDescription)")
                        }
                    }
                }

                HeaderButton("Show Paywall") {
                    PaywallService.shared.isShowingPaywall = true
                }
            }
        }
    }

    private var dictionaryTestingSection: some View {
        Section("Dictionary Testing") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Shared Dictionaries:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(dictionaryService.sharedDictionaries.count)")
                        .foregroundStyle(.secondary)
                }

                HeaderButton("Refresh Shared Dictionaries") {
                    dictionaryService.setupSharedDictionariesListener()
                }

                HeaderButton("Send Test Notification to User") {
                    showingEmailInput = true
                }

                HeaderButton("Clear Dictionary Cache") {
                    clearDictionaryCache()
                }


            }
        }
    }

    private var firebaseTestingSection: some View {
        Section("Firebase Testing") {
            VStack(alignment: .leading, spacing: 8) {
                HeaderButton("Test Firebase Connection") {
                    testFirebaseConnection()
                }

                HeaderButton("Check Firestore Rules") {
                    testFirestoreRules()
                }

                HeaderButton("Clear Local Cache") {
                    clearLocalCache()
                }
            }
        }
    }

    private var appTestingSection: some View {
        Section("App Testing") {
            VStack(alignment: .leading, spacing: 8) {
                HeaderButton("Reset App State") {
                    resetAppState()
                }

                HeaderButton("Show App Info") {
                    showAppInfo()
                }

                HeaderButton("Test Crash (Debug)") {
                    testCrash()
                }
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadUserInfo() {
        userEmail = authenticationService.userEmail ?? "Not signed in"
        userId = authenticationService.userId ?? "Not signed in"

        // Get FCM token using MessagingService
        Task {
            if let token = await MessagingService.shared.getCurrentToken() {
                fcmToken = token
            } else {
                fcmToken = "No token available"
            }
        }
    }

    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }

    // MARK: - Push Notification Testing

    private func testLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Debug Test Notification"
        content.body = "This is a test notification from debug panel"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "debug_test",
            "timestamp": Date().timeIntervalSince1970
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "debug-test", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert("Failed to schedule test notification: \(error.localizedDescription)")
                } else {
                    showAlert("Test notification scheduled successfully")
                }
            }
        }
    }

    private func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status = settings.authorizationStatus
                let message = """
                Notification Settings:
                Authorization: \(status.rawValue)
                Alert: \(settings.alertSetting.rawValue)
                Badge: \(settings.badgeSetting.rawValue)
                Sound: \(settings.soundSetting.rawValue)
                """
                showAlert(message)
            }
        }
    }

    // MARK: - Dictionary Testing

    private func clearDictionaryCache() {
        // Clear the shared dictionaries cache
        DispatchQueue.main.async {
            dictionaryService.sharedDictionaries.removeAll()
            showAlert("Dictionary cache cleared")
        }
    }

    // MARK: - Firebase Testing

    private func testFirebaseConnection() {
        let db = Firestore.firestore()
        db.collection("test").document("connection").setData([
            "timestamp": FieldValue.serverTimestamp(),
            "test": true
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert("Firebase connection failed: \(error.localizedDescription)")
                } else {
                    showAlert("Firebase connection successful")
                }
            }
        }
    }

    private func testFirestoreRules() {
        // Test read access
        let db = Firestore.firestore()
        db.collection("users").document("test").getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert("Firestore rules test failed: \(error.localizedDescription)")
                } else {
                    showAlert("Firestore rules test passed")
                }
            }
        }
    }

    private func clearLocalCache() {
        // Clear various caches
        URLCache.shared.removeAllCachedResponses()
        showAlert("Local cache cleared")
    }

    // MARK: - App Testing

    private func resetAppState() {
        // Reset various app states
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        showAlert("App state reset (restart app to see changes)")
    }

    private func showAppInfo() {
        let info = """
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
        Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")
        Firebase Project: my-dictionary-english
        """
        showAlert(info)
    }

    private func testCrash() {
        fatalError("Debug crash test")
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #endif
    }
}
#endif

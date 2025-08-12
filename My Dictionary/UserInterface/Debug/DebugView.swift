//
//  DebugView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//
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

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var fcmToken = "Loading..."
    @State private var userEmail = "Not signed in"
    @State private var userId = "Not signed in"
    @State private var testNotificationEmail = ""
    @State private var showingEmailInput = false

    var body: some View {
        NavigationView {
            List {
                userInfoSection
                pushNotificationsSection
                subscriptionTestingSection
                dictionaryTestingSection
                firebaseTestingSection
                appTestingSection
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Cancel", role: .cancel) {
                testNotificationEmail = ""
            }

            Button("Send") {
                sendTestNotificationToUser()
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
                        .foregroundStyle(subscriptionService.isProUser ? .green : .red)
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

                Button("Copy FCM Token") {
                    UIPasteboard.general.string = fcmToken
                    showAlert("FCM Token copied to clipboard")
                }
                .buttonStyle(.bordered)

                Button("Test Local Notification") {
                    testLocalNotification()
                }
                .buttonStyle(.bordered)

                Button("Request Notification Permission") {
                    Task {
                        await authenticationService.requestPushNotificationPermissions()
                    }
                }
                .buttonStyle(.bordered)

                Button("Check Notification Settings") {
                    checkNotificationSettings()
                }
                .buttonStyle(.bordered)
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
                    Text(subscriptionService.currentPlan?.rawValue ?? "None")
                        .foregroundStyle(.secondary)
                }

                Button("Refresh Subscription Status") {
                    Task {
                        await subscriptionService.checkSubscriptionStatus()
                    }
                }
                .buttonStyle(.bordered)

                Button("Sync Subscription to Firestore") {
                    Task {
                        await subscriptionService.syncSubscriptionStatus()
                        showAlert("Subscription status synced to Firestore")
                    }
                }
                .buttonStyle(.bordered)

                Button("Verify Subscription Ownership") {
                    Task {
                        let isOwner = await subscriptionService.verifySubscriptionOwnership()
                        showAlert(isOwner ? "Subscription ownership verified ✅" : "Subscription ownership failed ❌")
                    }
                }
                .buttonStyle(.bordered)

                Button("Test Paywall (Auth Check)") {
                    paywallService.presentPaywall(for: .createSharedDictionaries) { didSubscribe in
                        showAlert(didSubscribe ? "User subscribed! 🎉" : "User dismissed paywall")
                    }
                }
                .buttonStyle(.bordered)

                Button("Test Complete Auth Flow") {
                    Task {
                        await subscriptionService.setupAppUserID()
                        showAlert("Auth flow successful! ✅")
                    }
                }
                .buttonStyle(.bordered)

                Button("Test Immediate Sign Out") {
                    Task {
                        // First check current status
                        let wasPro = subscriptionService.isProUser

                        // Simulate sign out
                        subscriptionService.resetSubscriptionStatusOnSignOut()

                        let isProNow = subscriptionService.isProUser
                        showAlert("Before: \(wasPro ? "Pro" : "Free"), After: \(isProNow ? "Pro" : "Free")")
                    }
                }
                .buttonStyle(.bordered)

                Button("Create User Document") {
                    Task {
                        if let user = AuthenticationService.shared.currentUser {
                            await AuthenticationService.shared.createUserDocument(user: user)
                            showAlert("User document creation attempted")
                        } else {
                            showAlert("No authenticated user")
                        }
                    }
                }

                Button("Check User Document") {
                    Task {
                        guard let userEmail = AuthenticationService.shared.userEmail else {
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
                .buttonStyle(.bordered)

                Button("Show Paywall") {
                    // This would need to be implemented based on your paywall service
                    showAlert("Paywall functionality needs to be implemented")
                }
                .buttonStyle(.bordered)
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

                Button("Refresh Shared Dictionaries") {
                    dictionaryService.setupSharedDictionariesListener()
                }
                .buttonStyle(.bordered)

                Button("Test Add Collaborator") {
                    testAddCollaborator()
                }
                .buttonStyle(.bordered)

                Button("Test Push Notification") {
                    testPushNotification()
                }
                .buttonStyle(.bordered)

                Button("Send Test Notification to User") {
                    showingEmailInput = true
                }
                .buttonStyle(.bordered)

                Button("Clear Dictionary Cache") {
                    clearDictionaryCache()
                }
                .buttonStyle(.bordered)


            }
        }
    }

    private var firebaseTestingSection: some View {
        Section("Firebase Testing") {
            VStack(alignment: .leading, spacing: 8) {
                Button("Test Firebase Connection") {
                    testFirebaseConnection()
                }
                .buttonStyle(.bordered)

                Button("Check Firestore Rules") {
                    testFirestoreRules()
                }
                .buttonStyle(.bordered)

                Button("Clear Local Cache") {
                    clearLocalCache()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var appTestingSection: some View {
        Section("App Testing") {
            VStack(alignment: .leading, spacing: 8) {
                Button("Reset App State") {
                    resetAppState()
                }
                .buttonStyle(.bordered)

                Button("Show App Info") {
                    showAppInfo()
                }
                .buttonStyle(.bordered)

                Button("Test Crash (Debug)") {
                    testCrash()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Helper Methods

    private func loadUserInfo() {
        userEmail = authenticationService.userEmail ?? "Not signed in"
        userId = authenticationService.userId ?? "Not signed in"

        // Get FCM token
        Messaging.messaging().token { token, error in
            if let token = token {
                fcmToken = token
            } else if let error = error {
                fcmToken = "Error: \(error.localizedDescription)"
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

    private func testAddCollaborator() {
        guard let currentEmail = authenticationService.userEmail else {
            showAlert("No user email available")
            return
        }

        // This is a test - you would need to implement actual collaborator addition
        showAlert("Test collaborator addition would be implemented here")
    }

    private func testPushNotification() {
        Task {
            // Test with the first shared dictionary and current user
            guard let firstDictionary = dictionaryService.sharedDictionaries.first,
                  let userEmail = authenticationService.userEmail else {
                showAlert("No shared dictionaries or user email available")
                return
            }

            await dictionaryService.testCollaboratorNotification(
                dictionaryId: firstDictionary.id,
                targetEmail: userEmail
            )

            showAlert("Test push notification sent! Check your device.")
        }
    }

    private func sendTestNotificationToUser() {
        guard !testNotificationEmail.isEmpty else {
            showAlert("Please enter a valid email address")
            return
        }

        guard let firstDictionary = dictionaryService.sharedDictionaries.first else {
            showAlert("No shared dictionaries available")
            return
        }

        Task {
            do {
                await dictionaryService.testCollaboratorNotification(
                    dictionaryId: firstDictionary.id,
                    targetEmail: testNotificationEmail
                )

                DispatchQueue.main.async {
                    showAlert("Test notification sent to \(testNotificationEmail)!")
                    testNotificationEmail = ""
                }
            } catch {
                DispatchQueue.main.async {
                    showAlert("Failed to send test notification: \(error.localizedDescription)")
                }
            }
        }
    }

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
#if DEBUG
        fatalError("Debug crash test")
#else
        showAlert("Crash test only available in debug builds")
#endif
    }
}
#endif

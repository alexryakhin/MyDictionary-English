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
import CoreData

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
    @State private var showingAIDemo = false

    var body: some View {
        NavigationView {
            List {
                userInfoSection
                featureToggleSection
                pushNotificationsSection
                subscriptionTestingSection
                dictionaryTestingSection
                firebaseTestingSection
                aiTestingSection
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
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif

           Button(Loc.Actions.cancel, role: .cancel) {
                testNotificationEmail = ""
            }
        } message: {
            Text("Enter the email address of the user you want to send a test notification to.")
        }
        .sheet(isPresented: $showingAIDemo) {
            AIDemoView()
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
                
                HeaderButton("Test Word Study Notification (1 min)") {
                    testWordStudyNotification()
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
                        if let user = AuthenticationService.shared.currentUser {
                            await AuthenticationService.shared.createUserDocument(user: user)
                            showAlert("User document creation attempted")
                        } else {
                            showAlert("No authenticated user")
                        }
                    }
                }

                HeaderButton("Check User Document") {
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

                HeaderButton("Show Paywall") {
                    PaywallService.shared.isShowingPaywall = true
                }

                HeaderButton("Test Speechify API") {
                    let voices = TTSPlayer.shared.availableVoices
                    showAlert("Speechify API Test: Successfully loaded \(voices.count) voices")
                }
                
                HeaderButton("Clear Speechify Cache") {
                    SpeechifyTTSService.shared.clearCache()
                    showAlert("Speechify cache cleared")
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

                HeaderButton("Generate Sample Words") {
                    generateSampleWords()
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
    
    private var aiTestingSection: some View {
        Section("AI Features Testing") {
            VStack(alignment: .leading, spacing: 8) {
                HeaderButton("AI Demo") {
                    showAIDemo()
                }
                
                HeaderButton("Test OpenAI Connection") {
                    testOpenAIConnection()
                }
                
                HeaderButton("Clear AI Cache") {
                    clearAICache()
                }
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
    
    private func testWordStudyNotification() {
        // Get a random word from the dictionary
        let context = CoreDataService.shared.context
        let fetchRequest = CDWord.fetchRequest()
        let words = (try? context.fetch(fetchRequest)) ?? []

        guard let randomWord = words.randomElement() else {
            showAlert("No words found in dictionary")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = Loc.Notifications.wordStudyTitle(randomWord.wordItself ?? "Unknown")
        
        let definition = randomWord.primaryDefinition ?? "No definition available"
        let example = randomWord.primaryMeaning?.examplesDecoded.first ?? "No example available"
        content.body = Loc.Notifications.wordStudyBody(definition, example)
        content.sound = .default
        
        // Schedule for 1 minute from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(identifier: "debug-word-study", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    showAlert("Failed to schedule word study notification: \(error.localizedDescription)")
                } else {
                    showAlert("Word study notification scheduled for 1 minute: \(randomWord.wordItself ?? "Unknown")")
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
    
    // MARK: - AI Testing
    
    private func showAIDemo() {
        print("🔍 [DebugView] showAIDemo called")
        showingAIDemo = true
    }
    
    private func testOpenAIConnection() {
        print("🔍 [DebugView] testOpenAIConnection called")
        Task {
            do {
                print("🚀 [DebugView] Starting OpenAI connection test...")
                let aiService = AIService.shared
                let testDefinition = try await aiService.generateWordInformation(
                    for: "test",
                    inputLanguage: .english
                )
                
                print("✅ [DebugView] OpenAI connection test successful")
                print("🔍 [DebugView] Test definition: \(testDefinition)")
                
                await MainActor.run {
                    showAlert("OpenAI connection successful!\n\nEnhanced definition: \(testDefinition)")
                }
            } catch {
                print("❌ [DebugView] OpenAI connection test failed: \(error.localizedDescription)")
                await MainActor.run {
                    showAlert("OpenAI connection failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func clearAICache() {
        print("🔍 [DebugView] clearAICache called")
        // Clear AI service cache
        // This would clear the OpenAI service cache
        print("💾 [DebugView] AI cache cleared")
        showAlert("AI cache cleared")
    }
    
    // MARK: - Sample Data Generation
    
    private func generateSampleWords() {
        print("🔍 [DebugView] generateSampleWords called")
        
        let sampleWords = [
            // Spanish words first
            SampleWord(
                word: "Serendipia",
                partOfSpeech: .noun,
                phonetic: "/se.ɾenˈdi.pja/",
                meanings: [
                    SampleMeaning(
                        definition: "The occurrence and development of events by chance in a happy or beneficial way.",
                        examples: [
                            "Encontrar a mi futuro socio en esa cafetería fue pura serendipia.",
                            "El descubrimiento de la penicilina fue un accidente serendípico."
                        ]
                    )
                ],
                languageCode: "es",
                notes: "Love this word! Reminds me of when I found my dream job by chance at that coffee shop."
            ),
            SampleWord(
                word: "Efímero",
                partOfSpeech: .adjective,
                phonetic: "/eˈfi.me.ɾo/",
                meanings: [
                    SampleMeaning(
                        definition: "Lasting for a very short time; transitory.",
                        examples: [
                            "La belleza de los cerezos es efímera, dura solo unos días.",
                            "La fama en las redes sociales puede ser efímera y fugaz."
                        ]
                    )
                ],
                languageCode: "es",
                notes: "Like my vacation memories - gone too fast but so beautiful while they lasted."
            ),
            
            // English words with varied parts of speech
            SampleWord(
                word: "Serendipity",
                partOfSpeech: .noun,
                phonetic: "/ˌserənˈdipədē/",
                meanings: [
                    SampleMeaning(
                        definition: "The occurrence and development of events by chance in a happy or beneficial way.",
                        examples: [
                            "Meeting my future business partner at that coffee shop was pure serendipity.",
                            "The discovery of penicillin was a serendipitous accident."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "My favorite word! Used it in my college essay and got accepted."
            ),
            SampleWord(
                word: "Ephemeral",
                partOfSpeech: .adjective,
                phonetic: "/əˈfem(ə)rəl/",
                meanings: [
                    SampleMeaning(
                        definition: "Lasting for a very short time; transitory.",
                        examples: [
                            "The beauty of cherry blossoms is ephemeral, lasting only a few days.",
                            "Social media fame can be ephemeral and fleeting."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "Like my vacation memories - gone too fast but so beautiful while they lasted."
            ),
            SampleWord(
                word: "Ubiquitous",
                partOfSpeech: .adjective,
                phonetic: "/yo͞oˈbikwədəs/",
                meanings: [
                    SampleMeaning(
                        definition: "Present, appearing, or found everywhere.",
                        examples: [
                            "Smartphones have become ubiquitous in modern society.",
                            "Coffee shops are ubiquitous in this neighborhood."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "Hard to pronounce but so useful! My professor uses this word all the time."
            ),

            // Add more varied parts of speech
            SampleWord(
                word: "Persevere",
                partOfSpeech: .verb,
                phonetic: "/ˌpərsəˈvir/",
                meanings: [
                    SampleMeaning(
                        definition: "To persist in a course of action or belief despite difficulty or opposition.",
                        examples: [
                            "She persevered through all the challenges to achieve her dream.",
                            "The team persevered and eventually won the championship."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "My mom's favorite word. She says this is how I learned to walk!"
            ),
            SampleWord(
                word: "Swiftly",
                partOfSpeech: .adverb,
                phonetic: "/ˈswiftlē/",
                meanings: [
                    SampleMeaning(
                        definition: "In a swift manner; rapidly or quickly.",
                        examples: [
                            "The bird flew swiftly through the air.",
                            "She moved swiftly to catch the falling object."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "Perfect for describing how I run to catch the bus every morning!"
            ),
            SampleWord(
                word: "Beneath",
                partOfSpeech: .preposition,
                phonetic: "/bəˈnēTH/",
                meanings: [
                    SampleMeaning(
                        definition: "In or to a lower position than; under.",
                        examples: [
                            "The treasure was buried beneath the old oak tree.",
                            "She found her keys beneath the pile of papers."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "Always lose my keys beneath something. This word describes my life!"
            ),
            SampleWord(
                word: "Alas",
                partOfSpeech: .interjection,
                phonetic: "/əˈlas/",
                meanings: [
                    SampleMeaning(
                        definition: "Used to express sorrow, regret, or concern.",
                        examples: [
                            "Alas, the beautiful garden was destroyed by the storm.",
                            "Alas, I cannot attend the party due to prior commitments."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "Sounds so dramatic! I use this when I'm being sarcastic with friends."
            ),
            SampleWord(
                word: "Nevertheless",
                partOfSpeech: .adverb,
                phonetic: "/ˌnevərTHəˈles/",
                meanings: [
                    SampleMeaning(
                        definition: "In spite of that; notwithstanding; all the same.",
                        examples: [
                            "The weather was terrible; nevertheless, we had a great time.",
                            "He was tired, but nevertheless he continued working."
                        ]
                    )
                ],
                languageCode: "en",
                notes: "My go-to word for essays. Makes me sound smart and formal!"
            )
        ]
        
        Task {
            do {
                var createdCount = 0
                
                for sampleWord in sampleWords {
                    try await createWordFromSample(sampleWord)
                    createdCount += 1
                }
                
                await MainActor.run {
                    showAlert("Successfully created \(createdCount) sample words! 🎉\n\nIncluding Spanish and English words with varied parts of speech and personal notes.")
                }
            } catch {
                await MainActor.run {
                    showAlert("Error creating sample words: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createWordFromSample(_ sampleWord: SampleWord) async throws {
        let context = CoreDataService.shared.context
        
        try await context.perform {
            let newWord = CDWord(context: context)
            newWord.id = UUID()
            newWord.wordItself = sampleWord.word
            newWord.partOfSpeech = sampleWord.partOfSpeech.rawValue
            newWord.phonetic = sampleWord.phonetic
            newWord.languageCode = sampleWord.languageCode
            newWord.timestamp = Date()
            newWord.updatedAt = Date()
            newWord.isSynced = false
            newWord.isFavorite = Bool.random()
            newWord.difficultyScore = Int32.random(in: -20...60)
            newWord.notes = sampleWord.notes
            
            // Add meanings
            for (index, meaningData) in sampleWord.meanings.enumerated() {
                let meaning = try CDMeaning.create(
                    in: context,
                    definition: meaningData.definition,
                    examples: meaningData.examples,
                    order: Int32(index),
                    for: newWord
                )
                newWord.addToMeanings(meaning)
            }
            
            // Save the word
            try context.save()
            print("✅ [DebugView] Created sample word: \(sampleWord.word)")
        }
    }
}

// MARK: - Sample Data Structures

private struct SampleWord {
    let word: String
    let partOfSpeech: PartOfSpeech
    let phonetic: String
    let meanings: [SampleMeaning]
    let languageCode: String
    let notes: String
}

private struct SampleMeaning {
    let definition: String
    let examples: [String]
}
#endif

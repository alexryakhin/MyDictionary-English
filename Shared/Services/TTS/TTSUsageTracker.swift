//
//  TTSUsageTracker.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth

@MainActor
final class TTSUsageTracker: ObservableObject {

    static let shared = TTSUsageTracker()

    @Published var usageStats = TTSUsageStats()
    @Published var isSyncing = false

    private let userDefaults = UserDefaults.standard
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadUsageStats()
        setupFirebaseSync()
    }

    // MARK: - Firebase Sync Setup

    private func setupFirebaseSync() {
        // Listen for authentication changes to sync data
        AuthenticationService.shared.$authenticationState
            .sink { [weak self] state in
                if state == .signedIn {
                    Task { @MainActor in
                        // First load data FROM Firebase, then sync TO Firebase
                        await self?.loadUsageFromFirebase()
                        await self?.syncUsageToFirebase()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Firebase Sync Methods

    private func syncUsageToFirebase() async {
        guard let userEmail = AuthenticationService.shared.userEmail else { 
            print("❌ [TTSUsageTracker] No user email available")
            return 
        }
        
        print("🔍 [TTSUsageTracker] Attempting to sync with email: \(userEmail)")
        
        // Debug: Check current Firebase Auth user
        if let currentUser = Auth.auth().currentUser {
            print("🔍 [TTSUsageTracker] Firebase Auth user email: \(currentUser.email ?? "nil")")
            print("🔍 [TTSUsageTracker] Firebase Auth user UID: \(currentUser.uid)")
            print("🔍 [TTSUsageTracker] Firebase Auth user isEmailVerified: \(currentUser.isEmailVerified)")
        }
        
        await MainActor.run {
            isSyncing = true
        }
        defer {
            Task { @MainActor in
                isSyncing = false
            }
        }
        
        do {
            let usageData: [String: Any] = [
                "totalCharacters": usageStats.totalCharacters,
                "totalSessions": usageStats.totalSessions,
                "totalDuration": usageStats.totalDuration,
                "googleCharacters": usageStats.googleCharacters,
                "speechifyCharacters": usageStats.speechifyCharacters,
                "languageUsage": usageStats.languageUsage,
                "voiceUsage": usageStats.voiceUsage,
                "lastUsed": usageStats.lastUsed,
                "lastSynced": Timestamp(date: .now)
            ]
            
            print("🔍 [TTSUsageTracker] Writing to path: users/\(userEmail)/tts_usage/current")
            
            // Try to get the current user's ID token to debug the issue
            if let currentUser = Auth.auth().currentUser {
                do {
                    let idToken = try await currentUser.getIDToken()
                    print("🔍 [TTSUsageTracker] Successfully got ID token")
                    
                    // Decode the token to see what's in it (for debugging)
                    let tokenParts = idToken.components(separatedBy: ".")
                    if tokenParts.count >= 2 {
                        let payload = tokenParts[1]
                        if let data = Data(base64Encoded: payload + String(repeating: "=", count: (4 - payload.count % 4) % 4)),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("🔍 [TTSUsageTracker] Token payload: \(json)")
                        }
                    }
                } catch {
                    print("❌ [TTSUsageTracker] Failed to get ID token: \(error)")
                }
            }
            
            try await db.collection("users")
                .document(userEmail)
                .collection("tts_usage")
                .document("current")
                .setData(usageData, merge: true)
            
            print("✅ [TTSUsageTracker] Successfully synced usage to Firebase")
            
            // Sync monthly usage
            await syncMonthlyUsageToFirebase(userEmail: userEmail)
            
        } catch {
            print("❌ [TTSUsageTracker] Failed to sync usage to Firebase: \(error)")
            print("❌ [TTSUsageTracker] Error details: \(error.localizedDescription)")
        }
    }

    private func syncMonthlyUsageToFirebase(userEmail: String) async {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let monthlyKey = "\(currentYear)_\(currentMonth)"
        
        let monthlyUsage = getCurrentMonthSpeechifyUsage()
        
        do {
            let monthlyData: [String: Any] = [
                "usage": monthlyUsage,
                "limit": getMonthlySpeechifyLimit(),
                "lastUpdated": Timestamp(date: .now)
            ]
            
            try await db.collection("users")
                .document(userEmail)
                .collection("tts_monthly_usage")
                .document(monthlyKey)
                .setData(monthlyData, merge: true)
                
        } catch {
            print("❌ [TTSUsageTracker] Failed to sync monthly usage to Firebase: \(error)")
        }
    }

    private func loadUsageFromFirebase() async {
        guard let userEmail = AuthenticationService.shared.userEmail else { 
            print("❌ [TTSUsageTracker] No user email available for loading from Firebase")
            return 
        }

        print("🔍 [TTSUsageTracker] Loading usage from Firebase for email: \(userEmail)")

        do {
            // Load current usage stats
            let usageSnapshot = try await db.collection("users")
                .document(userEmail)
                .collection("tts_usage")
                .document("current")
                .getDocument()
            
            if let data = usageSnapshot.data() {
                print("✅ [TTSUsageTracker] Found Firebase data: \(data)")
                // Merge with local data (take the higher values)
                let firebaseStats = TTSUsageStats(
                    totalCharacters: data["totalCharacters"] as? Int ?? 0,
                    totalSessions: data["totalSessions"] as? Int ?? 0,
                    totalDuration: data["totalDuration"] as? TimeInterval ?? 0,
                    googleCharacters: data["googleCharacters"] as? Int ?? 0,
                    speechifyCharacters: data["speechifyCharacters"] as? Int ?? 0,
                    languageUsage: data["languageUsage"] as? [String: Int] ?? [:],
                    voiceUsage: data["voiceUsage"] as? [String: Int] ?? [:],
                    lastUsed: (data["lastUsed"] as? Timestamp)?.dateValue()
                )
                
                // Merge stats (take the higher values to avoid data loss)
                usageStats.totalCharacters = max(usageStats.totalCharacters, firebaseStats.totalCharacters)
                usageStats.totalSessions = max(usageStats.totalSessions, firebaseStats.totalSessions)
                usageStats.totalDuration = max(usageStats.totalDuration, firebaseStats.totalDuration)
                usageStats.googleCharacters = max(usageStats.googleCharacters, firebaseStats.googleCharacters)
                usageStats.speechifyCharacters = max(usageStats.speechifyCharacters, firebaseStats.speechifyCharacters)
                
                // Merge language and voice usage
                for (language, count) in firebaseStats.languageUsage {
                    usageStats.languageUsage[language] = max(usageStats.languageUsage[language] ?? 0, count)
                }
                
                for (voice, count) in firebaseStats.voiceUsage {
                    usageStats.voiceUsage[voice] = max(usageStats.voiceUsage[voice] ?? 0, count)
                }
                
                // Use the most recent lastUsed
                if let firebaseLastUsed = firebaseStats.lastUsed {
                    if let localLastUsed = usageStats.lastUsed {
                        usageStats.lastUsed = firebaseLastUsed > localLastUsed ? firebaseLastUsed : localLastUsed
                    } else {
                        usageStats.lastUsed = firebaseLastUsed
                    }
                }
                
                saveUsageStats()
                print("✅ [TTSUsageTracker] Successfully merged and saved Firebase data")
            } else {
                print("ℹ️ [TTSUsageTracker] No Firebase data found, using local data only")
            }
            
            // Load monthly usage
            await loadMonthlyUsageFromFirebase(userEmail: userEmail)
            
        } catch {
            print("❌ [TTSUsageTracker] Failed to load usage from Firebase: \(error)")
            print("❌ [TTSUsageTracker] Error details: \(error.localizedDescription)")
        }
    }

    private func loadMonthlyUsageFromFirebase(userEmail: String) async {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let monthlyKey = "\(currentYear)_\(currentMonth)"
        
        print("🔍 [TTSUsageTracker] Loading monthly usage from Firebase: \(monthlyKey)")
        
        do {
            let monthlySnapshot = try await db.collection("users")
                .document(userEmail)
                .collection("tts_monthly_usage")
                .document(monthlyKey)
                .getDocument()
            
            if let data = monthlySnapshot.data(),
               let firebaseUsage = data["usage"] as? Int {
                
                print("✅ [TTSUsageTracker] Found monthly Firebase data: \(data)")
                
                // Merge monthly usage (take the higher value)
                let localUsage = getCurrentMonthSpeechifyUsage()
                let mergedUsage = max(localUsage, firebaseUsage)
                
                print("🔍 [TTSUsageTracker] Monthly usage merge - Local: \(localUsage), Firebase: \(firebaseUsage), Merged: \(mergedUsage)")
                
                // Update local storage with merged value
                let key = "speechify_monthly_\(currentYear)_\(currentMonth)"
                userDefaults.set(mergedUsage, forKey: key)
                
                print("✅ [TTSUsageTracker] Successfully merged monthly usage")
            } else {
                print("ℹ️ [TTSUsageTracker] No monthly Firebase data found")
            }
        } catch {
            print("❌ [TTSUsageTracker] Failed to load monthly usage from Firebase: \(error)")
        }
    }

    // MARK: - Usage Tracking

    func trackTTSUsage(text: String, provider: TTSProvider, language: String, voice: String? = nil) {
        let characterCount = text.count

        // Check monthly limit for Speechify
        if provider == .speechify {
            let monthlyUsage = getCurrentMonthSpeechifyUsage()
            let monthlyLimit = getMonthlySpeechifyLimit()
            
            if monthlyUsage + characterCount > monthlyLimit {
                // Exceeded monthly limit - throw error
                return
            }
        }

        // Update total characters
        usageStats.totalCharacters += characterCount

        // Update provider-specific stats
        switch provider {
        case .google:
            usageStats.googleCharacters += characterCount
        case .speechify:
            usageStats.speechifyCharacters += characterCount
            updateMonthlySpeechifyUsage(characterCount)
        }

        // Update session count
        usageStats.totalSessions += 1

        // Update language stats
        if let existingCount = usageStats.languageUsage[language] {
            usageStats.languageUsage[language] = existingCount + characterCount
        } else {
            usageStats.languageUsage[language] = characterCount
        }

        // Update voice stats (for Speechify)
        if let voice {
            if let existingCount = usageStats.voiceUsage[voice] {
                usageStats.voiceUsage[voice] = existingCount + characterCount
            } else {
                usageStats.voiceUsage[voice] = characterCount
            }
        }

        // Update last usage time
        usageStats.lastUsed = Date()

        // Save stats locally
        saveUsageStats()

        // Sync to Firebase
        Task {
            await syncUsageToFirebase()
        }

        // Log for analytics
        AnalyticsService.shared.logEvent(.wordPlayed)
    }

    func trackTTSDuration(duration: TimeInterval) {
        usageStats.totalDuration += duration
        saveUsageStats()
    }

    // MARK: - Monthly Limits and Restrictions

    private let monthlySpeechifyLimit = 50_000 // 50,000 characters per month

    func getMonthlySpeechifyLimit() -> Int {
        return monthlySpeechifyLimit
    }

    func getCurrentMonthSpeechifyUsage() -> Int {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let key = "speechify_monthly_\(currentYear)_\(currentMonth)"
        return userDefaults.integer(forKey: key)
    }

    private func updateMonthlySpeechifyUsage(_ characterCount: Int) {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let key = "speechify_monthly_\(currentYear)_\(currentMonth)"
        let currentUsage = userDefaults.integer(forKey: key)
        userDefaults.set(currentUsage + characterCount, forKey: key)
    }

    func canUseSpeechify(text: String) -> Bool {
        let characterCount = text.count
        let monthlyUsage = getCurrentMonthSpeechifyUsage()
        let monthlyLimit = getMonthlySpeechifyLimit()
        
        return monthlyUsage + characterCount <= monthlyLimit
    }

    func getRemainingSpeechifyCharacters() -> Int {
        let monthlyUsage = getCurrentMonthSpeechifyUsage()
        let monthlyLimit = getMonthlySpeechifyLimit()
        
        return max(0, monthlyLimit - monthlyUsage)
    }

    func getSpeechifyUsagePercentage() -> Double {
        let monthlyUsage = getCurrentMonthSpeechifyUsage()
        let monthlyLimit = getMonthlySpeechifyLimit()
        
        return Double(monthlyUsage) / Double(monthlyLimit) * 100
    }

    func resetMonthlyUsage() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let key = "speechify_monthly_\(currentYear)_\(currentMonth)"
        userDefaults.removeObject(forKey: key)
        
        // Also reset in Firebase
        Task {
            await resetMonthlyUsageInFirebase()
        }
    }

    // MARK: - Manual Sync Methods

    func syncToFirebase() async {
        await syncUsageToFirebase()
    }

    func syncFromFirebase() async {
        await loadUsageFromFirebase()
    }

    private func resetMonthlyUsageInFirebase() async {
        guard let userEmail = AuthenticationService.shared.userEmail else { return }
        
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let monthlyKey = "\(currentYear)_\(currentMonth)"
        
        do {
            try await db.collection("users")
                .document(userEmail)
                .collection("tts_monthly_usage")
                .document(monthlyKey)
                .delete()
        } catch {
            print("❌ [TTSUsageTracker] Failed to reset monthly usage in Firebase: \(error)")
        }
    }

    // MARK: - Conflict Resolution

    private func resolveUsageConflict(local: TTSUsageStats, firebase: TTSUsageStats) -> TTSUsageStats {
        var resolved = TTSUsageStats()
        
        // Take the higher values to avoid data loss
        resolved.totalCharacters = max(local.totalCharacters, firebase.totalCharacters)
        resolved.totalSessions = max(local.totalSessions, firebase.totalSessions)
        resolved.totalDuration = max(local.totalDuration, firebase.totalDuration)
        resolved.googleCharacters = max(local.googleCharacters, firebase.googleCharacters)
        resolved.speechifyCharacters = max(local.speechifyCharacters, firebase.speechifyCharacters)
        
        // Merge language usage
        resolved.languageUsage = local.languageUsage
        for (language, count) in firebase.languageUsage {
            resolved.languageUsage[language] = max(resolved.languageUsage[language] ?? 0, count)
        }
        
        // Merge voice usage
        resolved.voiceUsage = local.voiceUsage
        for (voice, count) in firebase.voiceUsage {
            resolved.voiceUsage[voice] = max(resolved.voiceUsage[voice] ?? 0, count)
        }
        
        // Use the most recent lastUsed
        if let localLastUsed = local.lastUsed, let firebaseLastUsed = firebase.lastUsed {
            resolved.lastUsed = localLastUsed > firebaseLastUsed ? localLastUsed : firebaseLastUsed
        } else {
            resolved.lastUsed = local.lastUsed ?? firebase.lastUsed
        }
        
        return resolved
    }

    // MARK: - Statistics

    var totalCharactersFormatted: String {
        return usageStats.totalCharacters.formatted()
    }

    var totalSessionsFormatted: String {
        return usageStats.totalSessions.formatted()
    }

    var totalDurationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll

        let timeInterval = usageStats.totalDuration
        return formatter.string(from: timeInterval) ?? "0min"
    }

    var favoriteVoice: String {
        let sortedVoices = usageStats.voiceUsage.sorted { $0.value > $1.value }
        let voiceId = sortedVoices.first?.key
        if let voice = TTSPlayer.shared.availableVoices.first(where: { $0.id == voiceId }) {
            return voice.displayName
        }
        return "Default Voice"
    }

    var favoriteLanguage: String {
        let sortedLanguages = usageStats.languageUsage.sorted { $0.value > $1.value }
        return sortedLanguages.first?.key ?? "Unknown"
    }

    var timeSaved: String {
        // Estimate time saved based on reading speed (average 200 words per minute)
        let wordsPerMinute: Double = 200
        let charactersPerWord: Double = 5 // Average
        let totalWords = Double(usageStats.totalCharacters) / charactersPerWord
        let timeToRead = totalWords / wordsPerMinute

        let hours = Int(timeToRead) / 60
        let minutes = Int(timeToRead) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var providerUsagePercentage: Double {
        guard usageStats.totalCharacters > 0 else { return 0 }
        return Double(usageStats.speechifyCharacters) / Double(usageStats.totalCharacters) * 100
    }

    // MARK: - Data Management

    private func loadUsageStats() {
        if let data = userDefaults.data(forKey: "tts_usage_stats"),
           let stats = try? JSONDecoder().decode(TTSUsageStats.self, from: data) {
            usageStats = stats
        }
    }

    private func saveUsageStats() {
        if let data = try? JSONEncoder().encode(usageStats) {
            userDefaults.set(data, forKey: "tts_usage_stats")
        }
    }

    // MARK: - Helper Methods

    func resetStats() {
        usageStats = TTSUsageStats()
        saveUsageStats()
    }

    func exportStats() -> String {
        let stats = """
        TTS Usage Statistics
        
        Total Characters: \(totalCharactersFormatted)
        Total Sessions: \(totalSessionsFormatted)
        Total Duration: \(totalDurationFormatted)
        Time Saved: \(timeSaved)
        
        Provider Usage:
        - Google TTS: \(usageStats.googleCharacters.formatted()) characters
        - Speechify: \(usageStats.speechifyCharacters.formatted()) characters
        - Premium Usage: \(String(format: "%.1f", providerUsagePercentage))%
        
        Favorite Voice: \(favoriteVoice)
        Favorite Language: \(favoriteLanguage)
        
        Last Used: \(usageStats.lastUsed?.formatted() ?? "Never")
        """

        return stats
    }
}

// MARK: - Data Models

struct TTSUsageStats: Codable {
    var totalCharacters: Int = 0
    var totalSessions: Int = 0
    var totalDuration: TimeInterval = 0
    var googleCharacters: Int = 0
    var speechifyCharacters: Int = 0
    var languageUsage: [String: Int] = [:]
    var voiceUsage: [String: Int] = [:]
    var lastUsed: Date?

    // Weekly/Monthly tracking
    var weeklyCharacters: Int = 0
    var monthlyCharacters: Int = 0
    var weeklySessions: Int = 0
    var monthlySessions: Int = 0
}

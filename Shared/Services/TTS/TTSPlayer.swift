//
//  TTSPlayer.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import AVFoundation
import SwiftUI

final class TTSPlayer: NSObject, ObservableObject {

    static let shared = TTSPlayer()

    private var player: AVAudioPlayer?
    private var speechSynthesizer: AVSpeechSynthesizer?
    @AppStorage(UDKeys.selectedTTSRegion) private var selectedTTSRegion: CountryRegion = .unitedStates
    @AppStorage(UDKeys.selectedTTSProvider) var selectedTTSProvider: TTSProvider = .google
    @AppStorage(UDKeys.selectedSpeechifyVoice) var selectedSpeechifyVoice: String = "erik"
    @AppStorage(UDKeys.selectedSpeechifyModel) var selectedSpeechifyModel: SpeechifyModel = .multilingual
    @AppStorage(UDKeys.ttsSpeechRate) var speechRate: Double = 1.0
    @AppStorage(UDKeys.ttsVolume) var volume: Double = 1.0

    private let speechifyService: SpeechifyTTSService = .shared

    @Published var isPlaying = false
    @Published var availableVoices: [SpeechifyVoice] = []
    @Published var testText: String = "Hello there! How are you?"

    var selectedSpeechifyVoiceModel: SpeechifyVoice? {
        availableVoices.first(where: { $0.id == selectedSpeechifyVoice })
    }

    private override init() {
        super.init()
        setupSpeechSynthesizer()
        loadAvailableVoices()
    }

    func play(_ text: String, languageCode: String? = nil) async throws {
        guard text.isNotEmpty, !isPlaying else { return }
        let detectedLanguageCode = languageCode ?? LanguageDetector.shared.detectLanguage(for: text).languageCode
        
        // Build locale code with selected region (e.g., "en-US", "es-MX")
        let localeCode = selectedTTSRegion.localeCode(for: detectedLanguageCode)

        // Determine which provider to use
        let provider = determineProvider(for: localeCode)

        // Check Speechify usage limits if using Speechify
        if provider == .speechify {
            if await !TTSUsageTracker.shared.canUseSpeechify(text: text) {
                throw TTSError.monthlyLimitExceeded
            }
        }

        do {
            switch provider {
            case .google:
                try await playWithGoogle(text: text, targetLanguage: localeCode)
            case .speechify:
                try await playWithSpeechify(
                    text: text,
                    voice: selectedSpeechifyVoice,
                    targetLanguage: detectedLanguageCode
                )
            case .system:
                try await playWithSystem(text: text, languageCode: localeCode)
            }

            // Track usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: provider,
                    language: detectedLanguageCode,
                    voice: provider == .speechify ? selectedSpeechifyVoice : nil
                )
            }
        } catch TTSError.premiumFeatureRequired {
            // Fallback to Google TTS if premium feature is required but not available
            try await playWithGoogle(text: text, targetLanguage: localeCode)

            // Track fallback usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: .google,
                    language: detectedLanguageCode
                )
            }
        } catch TTSError.monthlyLimitExceeded {
            // Fallback to Google TTS if monthly limit is exceeded
            try await playWithGoogle(text: text, targetLanguage: localeCode)

            // Track fallback usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: .google,
                    language: detectedLanguageCode
                )
            }
        } catch {
            throw error
        }
    }

    func previewSpeechifyVoice(_ voice: SpeechifyVoice) async throws {
        // Use the actual preview audio if available
        if let previewAudioURL = voice.bestPreviewAudioURL,
           let url = URL(string: previewAudioURL) {
            // Download the remote audio file first, then play it
            let temporaryDownloadURL = try await temporaryDownloadURL(for: url)
            try await play(from: temporaryDownloadURL)
        } else {
            // Fallback to text-to-speech if no preview audio is available
            try await playWithSpeechify(
                text: testText,
                voice: voice.id,
                targetLanguage: voice.language
            )
        }
    }

    private func determineProvider(for targetLanguage: String) -> TTSProvider {
        // Check if user is offline - use system TTS as backup
        let reachabilityService = ReachabilityService.shared
        if reachabilityService.isOffline {
            return .system
        }

        // If user selected Speechify and has premium, use it
        if selectedTTSProvider == .speechify && SubscriptionService.shared.isProUser {
            return .speechify
        }

        // Otherwise use Google TTS
        return .google
    }

    private func playWithGoogle(text: String, targetLanguage: String) async throws {
        // Check cache first
        let cacheKey = generateCacheKey(text: text, language: targetLanguage, provider: .google, voice: nil)
        if let cachedURL = getCachedAudioFile(for: cacheKey) {
            print("🎵 [TTSPlayer] Using cached Google TTS audio for: \(text.prefix(20))...")
#if os(iOS)
            let _ = try setupAudioSession()
#endif
            try await play(from: cachedURL)
            return
        }
        
        let escapedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=\(escapedText)&tl=\(targetLanguage)"
        guard let url = URL(string: urlString) else { return }

#if os(iOS)
        let _ = try setupAudioSession()
#endif

        let temporaryDownloadURL = try await temporaryDownloadURL(for: url)
        
        // Cache the downloaded file
        cacheAudioFile(url: temporaryDownloadURL, for: cacheKey)
        
        try await play(from: temporaryDownloadURL)
    }

    private func playWithSpeechify(text: String, voice: String, targetLanguage: String) async throws {
        // Check cache first
        let cacheKey = generateCacheKey(text: text, language: targetLanguage, provider: .speechify, voice: voice)
        if let cachedURL = getCachedAudioFile(for: cacheKey) {
            print("🎵 [TTSPlayer] Using cached Speechify TTS audio for: \(text.prefix(20))...")
#if os(iOS)
            let _ = try setupAudioSession()
#endif
            try await play(from: cachedURL)
            return
        }
        
        let request = TTSRequest(
            text: text,
            language: targetLanguage,
            voice: voice,
            provider: .speechify,
            model: selectedSpeechifyModel,
            audioFormat: "wav"
        )

        let response = try await speechifyService.synthesizeSpeech(request: request)

        // Save audio data to temporary file and play
        let tempURL = try saveAudioDataToTempFile(response.audioData, cacheKey: cacheKey)
        
#if os(iOS)
        let _ = try setupAudioSession()
#endif
        try await play(from: tempURL)
    }

    private func playWithSystem(text: String, languageCode: String) async throws {
        guard let synthesizer = speechSynthesizer else {
            throw CoreError.internalError(.cannotSetupAudioSession)
        }

#if os(iOS)
        let _ = try setupAudioSession()
#endif

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        // Create utterance with the text
        let utterance = AVSpeechUtterance(string: text)

        // Set language
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)

        // Apply user preferences
        utterance.rate = Float(speechRate * 0.5) // Scale down for better control
        utterance.volume = Float(volume)
        utterance.pitchMultiplier = 1.0

        // Update UI state
        await MainActor.run {
            isPlaying = true
        }

        synthesizer.speak(utterance)
    }

    private func saveAudioDataToTempFile(_ audioData: Data, cacheKey: String? = nil) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = cacheKey != nil ? "\(cacheKey!).wav" : "speechify_audio_\(UUID().uuidString).wav"
        let tempFile = tempDir.appendingPathComponent(filename)
        print("✅ [TTSPlayer] Successfully saved temporary file to \(tempFile.path)")

        try audioData.write(to: tempFile)
        return tempFile
    }

    func loadAvailableVoices() {
        guard availableVoices.isEmpty else { return }

        do {
            availableVoices = try speechifyService.getAvailableVoices()
        } catch {
            availableVoices = []
        }
    }

    private func setupSpeechSynthesizer() {
        speechSynthesizer = AVSpeechSynthesizer()
        speechSynthesizer?.delegate = self
    }

#if os(iOS)
    private func setupAudioSession() throws -> AVAudioSession {
        let session = AVAudioSession.sharedInstance()
        
        // Check if audio session is already configured correctly
        if session.category == .playback && session.isOtherAudioPlaying == false {
            print("🔊 [TTSPlayer] Audio session already configured correctly")
            return session
        }
        
        do {
            // Configure audio session to play even in silent mode
            // Use .playback category with .mixWithOthers to allow playing in silent mode
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            
            // Only activate if not already active
            if !session.isOtherAudioPlaying {
                try session.setActive(true)
            }
            
            print("🔊 [TTSPlayer] Audio session configured successfully")
            return session
        } catch {
            print("❌ [TTSPlayer] Failed to setup audio session: \(error.localizedDescription)")
            // Try a simpler configuration as fallback
            do {
                try session.setCategory(.playback)
                if !session.isOtherAudioPlaying {
                    try session.setActive(true)
                }
                print("🔊 [TTSPlayer] Audio session configured with fallback settings")
                return session
            } catch {
                print("❌ [TTSPlayer] Fallback audio session setup also failed: \(error.localizedDescription)")
                // Don't throw error, just return the session as-is
                print("⚠️ [TTSPlayer] Continuing with existing audio session configuration")
                return session
            }
        }
    }
#endif

    private func temporaryDownloadURL(for url: URL) async throws -> URL {
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

        do {
            let (tempURL, _) = try await URLSession.shared.download(for: request)

            // Copy the downloaded file to a more permanent temporary location
            let tempDir = FileManager.default.temporaryDirectory
            let permanentTempFile = tempDir.appendingPathComponent("preview_audio_\(UUID().uuidString).mp3")

            try FileManager.default.copyItem(at: tempURL, to: permanentTempFile)
            print("✅ [TTSPlayer] Successfully saved preview audio to \(permanentTempFile.path)")

            return permanentTempFile
        } catch {
            throw CoreError.networkError(.noData)
        }
    }

    @MainActor
    private func play(from url: URL) throws {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self

            // Enable rate modification
            player?.enableRate = true

            // Apply audio settings
            player?.rate = Float(speechRate)
            player?.volume = Float(volume)

            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
            logError("Cannot play audio file: \(error), url: \(url)")
            throw CoreError.internalError(.cannotPlayAudio)
        }
    }

    func stop() {
        player?.stop()
        speechSynthesizer?.stopSpeaking(at: .immediate)
        isPlaying = false
    }
    
    // MARK: - Caching Methods
    
    private func generateCacheKey(text: String, language: String, provider: TTSProvider, voice: String?) -> String {
        let voicePart = voice != nil ? "_\(voice!)" : ""
        let keyString = "\(provider.rawValue)_\(language)\(voicePart)_\(text)"
        return keyString.data(using: .utf8)?.base64EncodedString().replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-") ?? UUID().uuidString
    }
    
    private func getCachedAudioFile(for cacheKey: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let cachedFile = tempDir.appendingPathComponent("\(cacheKey).wav")
        
        // Check if file exists and is not too old (7 days)
        if FileManager.default.fileExists(atPath: cachedFile.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: cachedFile.path)
                if let creationDate = attributes[.creationDate] as? Date {
                    let age = Date().timeIntervalSince(creationDate)
                    if age < 30 * 24 * 60 * 60 { // 30 days
                        return cachedFile
                    } else {
                        // File is too old, remove it
                        try FileManager.default.removeItem(at: cachedFile)
                    }
                }
            } catch {
                print("⚠️ [TTSPlayer] Error checking cached file: \(error)")
            }
        }
        
        return nil
    }
    
    private func cacheAudioFile(url: URL, for cacheKey: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let cachedFile = tempDir.appendingPathComponent("\(cacheKey).wav")
        
        do {
            // Copy the temporary file to the cached location
            if FileManager.default.fileExists(atPath: cachedFile.path) {
                try FileManager.default.removeItem(at: cachedFile)
            }
            try FileManager.default.copyItem(at: url, to: cachedFile)
            print("💾 [TTSPlayer] Cached audio file: \(cacheKey)")
        } catch {
            print("⚠️ [TTSPlayer] Failed to cache audio file: \(error)")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension TTSPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSPlayer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}

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
    @AppStorage(UDKeys.selectedEnglishAccent) private var selectedEnglishAccent: EnglishAccent = .american
    @AppStorage(UDKeys.selectedTTSProvider) var selectedTTSProvider: TTSProvider = .google
    @AppStorage(UDKeys.selectedSpeechifyVoice) var selectedSpeechifyVoice: String = "en-US-1"
    @AppStorage(UDKeys.selectedSpeechifyModel) var selectedSpeechifyModel: SpeechifyModel = .multilingual
    @AppStorage("tts_speech_rate") var speechRate: Double = 1.0
    @AppStorage("tts_pitch") var pitch: Double = 1.0
    @AppStorage("tts_volume") var volume: Double = 1.0

    let speechifyService: SpeechifyTTSService?
    
    @Published var isPlaying = false
    @Published var availableVoices: [SpeechifyVoice] = []
    @Published var testText: String = "Hello there! How are you?"

    private override init() {
        self.speechifyService = SpeechifyTTSService(apiKey: AppConfig.Speechify.apiKey)
        super.init()
        // Initialize Speechify service with API key from config

        // Load available voices for Speechify
        Task {
            await loadAvailableVoices()
        }
    }
    
    func play(_ text: String, targetLanguage: String?) async throws {
        guard text.isNotEmpty, !isPlaying else { return }
        
        // Determine which provider to use
        let provider = determineProvider(for: targetLanguage)
        
        do {
            switch provider {
            case .google:
                try await playWithGoogle(text: text, targetLanguage: targetLanguage)
            case .speechify:
                try await playWithSpeechify(
                    text: text,
                    voice: selectedSpeechifyVoice,
                    targetLanguage: targetLanguage
                )
            }
            
            // Track usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: provider,
                    language: targetLanguage ?? "en",
                    voice: provider == .speechify ? selectedSpeechifyVoice : nil
                )
            }
        } catch TTSError.premiumFeatureRequired {
            // Fallback to Google TTS if premium feature is required but not available
            try await playWithGoogle(text: text, targetLanguage: targetLanguage)
            
            // Track fallback usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: .google,
                    language: targetLanguage ?? "en"
                )
            }
        } catch {
            throw error
        }
    }

    func previewSpeechifyVoice(_ voice: SpeechifyVoice) async throws {
        try await playWithSpeechify(
            text: testText,
            voice: voice.id,
            targetLanguage: voice.language
        )
    }

    private func determineProvider(for targetLanguage: String?) -> TTSProvider {
        // If user selected Speechify and has premium, use it
        if selectedTTSProvider == .speechify && SubscriptionService.shared.isProUser {
            return .speechify
        }
        
        // Otherwise use Google TTS
        return .google
    }
    
    private func playWithGoogle(text: String, targetLanguage: String?) async throws {
        var tl: String?
        if targetLanguage == nil || targetLanguage == "en" {
            tl = selectedEnglishAccent.localeCode
        } else {
            tl = targetLanguage
        }

        let escapedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=\(escapedText)&tl=\(tl ?? selectedEnglishAccent.localeCode)"
        guard let url = URL(string: urlString) else { return }

        #if os(iOS)
        let _ = try setupAudioSession()
        #endif
        
        let temporaryDownloadURL = try await temporaryDownloadURL(for: url)
        try await play(from: temporaryDownloadURL)
    }
    
    private func playWithSpeechify(text: String, voice: String, targetLanguage: String?) async throws {
        guard let speechifyService = speechifyService else {
            throw TTSError.invalidAPIKey
        }
        
        let request = TTSRequest(
            text: text,
            language: targetLanguage ?? "en-US",
            voice: voice,
            provider: .speechify,
            model: selectedSpeechifyModel,
            audioFormat: "wav"
        )
        
        let response = try await speechifyService.synthesizeSpeech(request: request)
        
        // Save audio data to temporary file and play
        let tempURL = try saveAudioDataToTempFile(response.audioData)
        try await play(from: tempURL)
    }
    
    private func saveAudioDataToTempFile(_ audioData: Data) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("speechify_audio_\(UUID().uuidString).wav")
        print("✅ [TTSPlayer] Successfully saved temporary file to \(tempFile.path)")

        try audioData.write(to: tempFile)
        return tempFile
    }
    
    @MainActor
    func loadAvailableVoices() async {
        guard availableVoices.isEmpty else { return }

        guard let speechifyService = speechifyService else {
            print("⚠️ [TTSPlayer] Speechify service not available")
            return 
        }
        
        do {
            print("🔄 [TTSPlayer] Loading Speechify voices...")
            availableVoices = try await speechifyService.getAvailableVoices()
            print("✅ [TTSPlayer] Successfully loaded \(availableVoices.count) voices")
        } catch TTSError.invalidAPIKey {
            print("❌ [TTSPlayer] Speechify API key is invalid or missing")
            availableVoices = []
        } catch TTSError.premiumFeatureRequired {
            print("⚠️ [TTSPlayer] Premium required for Speechify voices")
            availableVoices = []
        } catch {
            print("❌ [TTSPlayer] Failed to load Speechify voices: \(error)")
            availableVoices = []
        }
    }

    #if os(iOS)
    private func setupAudioSession() throws -> AVAudioSession {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback)
            try session.setActive(true)
            return session
        } catch {
            throw CoreError.internalError(.cannotSetupAudioSession)
        }
    }
    #endif

    private func temporaryDownloadURL(for url: URL) async throws -> URL {
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)

        do {
            let (url, _) = try await URLSession.shared.download(for: request)
            return url
        } catch {
            throw CoreError.networkError(.noData)
        }
    }

    @MainActor
    private func play(from url: URL) throws {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
            throw CoreError.internalError(.cannotPlayAudio)
        }
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
    }
}

// MARK: - AVAudioPlayerDelegate

extension TTSPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

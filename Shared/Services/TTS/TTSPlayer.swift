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
        loadAvailableVoices()
    }
    
    func play(_ text: String) async throws {
        guard text.isNotEmpty, !isPlaying else { return }
        let detectedLanguage = LanguageDetector.shared.detectLanguage(for: text)
        let selectedAccent = detectedLanguage == .english
        ? selectedEnglishAccent.localeCode
        : detectedLanguage.languageCode

        // Determine which provider to use
        let provider = determineProvider(for: selectedAccent)

        // Check Speechify usage limits if using Speechify
        if provider == .speechify {
            if await !TTSUsageTracker.shared.canUseSpeechify(text: text) {
                throw TTSError.monthlyLimitExceeded
            }
        }
        
        do {
            switch provider {
            case .google:
                try await playWithGoogle(text: text, targetLanguage: selectedAccent)
            case .speechify:
                try await playWithSpeechify(
                    text: text,
                    voice: selectedSpeechifyVoice,
                    targetLanguage: detectedLanguage.languageCode
                )
            }
            
            // Track usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: provider,
                    language: detectedLanguage.languageCode,
                    voice: provider == .speechify ? selectedSpeechifyVoice : nil
                )
            }
        } catch TTSError.premiumFeatureRequired {
            // Fallback to Google TTS if premium feature is required but not available
            try await playWithGoogle(text: text, targetLanguage: selectedAccent)

            // Track fallback usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: .google,
                    language: detectedLanguage.languageCode
                )
            }
        } catch TTSError.monthlyLimitExceeded {
            // Fallback to Google TTS if monthly limit is exceeded
            try await playWithGoogle(text: text, targetLanguage: selectedAccent)

            // Track fallback usage
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: text,
                    provider: .google,
                    language: detectedLanguage.languageCode
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
        // If user selected Speechify and has premium, use it
        if selectedTTSProvider == .speechify && SubscriptionService.shared.isProUser {
            return .speechify
        }
        
        // Otherwise use Google TTS
        return .google
    }
    
    private func playWithGoogle(text: String, targetLanguage: String) async throws {
        let escapedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=\(escapedText)&tl=\(targetLanguage)"
        guard let url = URL(string: urlString) else { return }

        #if os(iOS)
        let _ = try setupAudioSession()
        #endif
        
        let temporaryDownloadURL = try await temporaryDownloadURL(for: url)
        try await play(from: temporaryDownloadURL)
    }
    
    private func playWithSpeechify(text: String, voice: String, targetLanguage: String) async throws {
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
    
    func loadAvailableVoices() {
        guard availableVoices.isEmpty else { return }

        do {
            availableVoices = try speechifyService.getAvailableVoices()
        } catch {
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
        isPlaying = false
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

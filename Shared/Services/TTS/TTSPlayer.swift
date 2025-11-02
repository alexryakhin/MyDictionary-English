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
    
    // Chunking support
    private var textChunks: [String] = []
    private var currentChunkIndex: Int = 0
    private var currentLanguageCode: String?
    private var currentLocaleCode: String? // Store the computed locale code for chunks
    private var chunkProvider: TTSProvider?
    private var currentChunkFinished = false // Track when current chunk finishes
    private var isPaused = false // Track if playback is paused (not stopped)
    private var pausedOriginalText: String? // Store original text for resume

    @Published var isPlaying = false
    @Published var availableVoices: [SpeechifyVoice] = []
    @Published var testText: String = "Hello there! How are you?"
    @Published var currentPlayingChunk: String? = nil // Currently playing chunk text for highlighting

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
        
        // If there's paused chunked playback, stop it first when playing a single word
        // (don't want to resume story when playing a word)
        if isPaused && chunkProvider != nil {
            stop()
        }
        
        // Preprocess text for TTS - remove underscores and other non-speech characters
        let processedText = preprocessTextForTTS(text)
        
        let detectedLanguageCode = languageCode ?? LanguageDetector.shared.detectLanguage(for: processedText).languageCode
        
        // Build locale code with appropriate region (e.g., "en-US", "es-MX")
        // If languageCode was explicitly provided (e.g., from Story Lab), use an appropriate region for that language
        // Otherwise, use the user's TTS region preference
        let localeCode: String
        if let explicitLanguageCode = languageCode {
            // Language is known from context (e.g., Story Lab), use appropriate region for that language
            let popularRegions = CountryRegion.popularRegions(for: explicitLanguageCode)
            // Check if we have a meaningful region (not just the default fallback)
            // For languages without explicit support, popularRegions will return [.unitedStates] as default
            // We want to avoid "ru-US" and instead use just "ru"
            if !popularRegions.isEmpty && explicitLanguageCode.lowercased() == "en" {
                // English always has regions, use the first one
                localeCode = popularRegions.first!.localeCode(for: explicitLanguageCode)
            } else if !popularRegions.isEmpty && popularRegions.first != .unitedStates {
                // We have a specific region for this language (not the default fallback)
                localeCode = popularRegions.first!.localeCode(for: explicitLanguageCode)
            } else {
                // No appropriate region found, use just the language code (Google TTS accepts this)
                localeCode = explicitLanguageCode
            }
        } else {
            // Auto-detected language, use user's TTS region preference
            localeCode = selectedTTSRegion.localeCode(for: detectedLanguageCode)
        }

        // Determine which provider to use
        let provider = determineProvider(for: localeCode)

        // Check if text is long (>= 200 characters) and needs chunking
        if processedText.count >= 200 {
            // Split text into sentences for chunking
            let chunks = splitIntoSentences(processedText)
            
            // Check Speechify usage limits if using Speechify
            if provider == .speechify {
                let totalChars = processedText.count
                if await !TTSUsageTracker.shared.canUseSpeechify(text: processedText) {
                    // Fallback to Google for chunked text
                    try await playChunkedText(chunks: chunks, targetLanguage: localeCode, detectedLanguage: detectedLanguageCode, provider: .google, originalText: processedText)
                    return
                }
            }
            
            // Play chunks sequentially
            try await playChunkedText(chunks: chunks, targetLanguage: localeCode, detectedLanguage: detectedLanguageCode, provider: provider, originalText: processedText)
            return
        }
        
        // For short text, use existing behavior
        // Check Speechify usage limits if using Speechify
        if provider == .speechify {
            if await !TTSUsageTracker.shared.canUseSpeechify(text: text) {
                throw TTSError.monthlyLimitExceeded
            }
        }

        do {
            switch provider {
            case .google:
                try await playWithGoogle(text: processedText, targetLanguage: localeCode)
            case .speechify:
                try await playWithSpeechify(
                    text: processedText,
                    voice: selectedSpeechifyVoice,
                    targetLanguage: detectedLanguageCode
                )
            case .system:
                try await playWithSystem(text: processedText, languageCode: localeCode)
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
            try await playWithGoogle(text: processedText, targetLanguage: localeCode)

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
            try await playWithGoogle(text: processedText, targetLanguage: localeCode)

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
    
    // MARK: - Chunking Support
    
    private func splitIntoSentences(_ text: String) -> [String] {
        // Split by sentence terminators (. ! ?) while keeping the terminators
        // Use regex to match: text ending with . ! or ? followed by space or end of string
        let pattern = #"([^.!?]+[.!?])\s*"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            // Fallback: simple split by terminators and reconstruct
            return simpleSentenceSplit(text)
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        var sentences: [String] = []
        var lastIndex = 0
        
        for match in matches {
            if let sentenceRange = Range(match.range, in: text) {
                let sentence = String(text[sentenceRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
                lastIndex = match.range.location + match.range.length
            }
        }
        
        // Add remaining text if any (might not end with terminator)
        if lastIndex < text.utf16.count {
            let remainingStartIndex = String.Index(utf16Offset: lastIndex, in: text)
            let remaining = String(text[remainingStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remaining.isEmpty {
                sentences.append(remaining)
            }
        }
        
        // Fallback if no matches found
        if sentences.isEmpty {
            return simpleSentenceSplit(text)
        }
        
        return sentences.filter { !$0.isEmpty }
    }
    
    private func simpleSentenceSplit(_ text: String) -> [String] {
        // Simple fallback: split by sentence terminators
        var sentences: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            if ".!?".contains(char) {
                let trimmed = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    sentences.append(trimmed)
                }
                currentSentence = ""
            }
        }
        
        // Add remaining text if any
        let trimmed = currentSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            sentences.append(trimmed)
        }
        
        return sentences.isEmpty ? [text] : sentences
    }
    
    private func playChunkedText(chunks: [String], targetLanguage: String, detectedLanguage: String, provider: TTSProvider, originalText: String) async throws {
        guard !chunks.isEmpty else { return }
        
        // Initialize chunking state and set isPlaying to true for entire session
        await MainActor.run {
            textChunks = chunks
            currentLanguageCode = detectedLanguage
            currentLocaleCode = targetLanguage // Store the computed locale code
            chunkProvider = provider
            pausedOriginalText = originalText
            isPaused = false
            // Only reset currentChunkIndex if starting fresh (not resuming)
            if currentChunkIndex >= textChunks.count {
                currentChunkIndex = 0
            }
            isPlaying = true // Set to true for entire chunked session
        }
        
        // Play from current chunk
        try await playNextChunk(originalText: originalText, detectedLanguage: detectedLanguage, provider: provider)
    }
    
    private func playNextChunk(originalText: String, detectedLanguage: String, provider: TTSProvider) async throws {
        guard await MainActor.run(body: { currentChunkIndex < textChunks.count }) else {
            // All chunks played
            await MainActor.run {
                textChunks = []
                currentChunkIndex = 0
                currentLanguageCode = nil
                currentLocaleCode = nil
                chunkProvider = nil
                currentChunkFinished = false
                currentPlayingChunk = nil
                isPlaying = false
            }
            
            // Track total usage for all chunks
            await MainActor.run {
                TTSUsageTracker.shared.trackTTSUsage(
                    text: originalText,
                    provider: provider,
                    language: detectedLanguage,
                    voice: provider == .speechify ? selectedSpeechifyVoice : nil
                )
            }
            return
        }
        
        let chunk: String = textChunks[currentChunkIndex]
        // Use the stored locale code if available (from explicit language context), otherwise compute it
        let localeCode: String = await MainActor.run {
            if let storedLocaleCode = currentLocaleCode {
                return storedLocaleCode
            } else {
                // Fallback to user's TTS region preference for auto-detected languages
                return selectedTTSRegion.localeCode(for: detectedLanguage)
            }
        }

        // Update current playing chunk for highlighting
        await MainActor.run {
            currentPlayingChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            switch provider {
            case .google:
                try await playWithGoogle(text: chunk, targetLanguage: localeCode)
            case .speechify:
                try await playWithSpeechify(
                    text: chunk,
                    voice: selectedSpeechifyVoice,
                    targetLanguage: detectedLanguage
                )
            case .system:
                try await playWithSystem(text: chunk, languageCode: localeCode)
            }
            
            // Wait for this chunk to finish playing before playing next
            // The delegate will call continueChunking() when done
            await waitForChunkCompletion()
            
        } catch {
            // If error occurs, stop chunking
            await MainActor.run {
                textChunks = []
                currentChunkIndex = 0
                currentLanguageCode = nil
                currentLocaleCode = nil
                chunkProvider = nil
                currentChunkFinished = false
                currentPlayingChunk = nil
                isPlaying = false
            }
            throw error
        }
    }
    
    private func waitForChunkCompletion() async {
        // Reset chunk finished flag
        await MainActor.run {
            currentChunkFinished = false
        }
        
        // Wait for current chunk to finish (tracked by delegate methods)
        while await MainActor.run(body: { !currentChunkFinished && chunkProvider != nil }) {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Small delay before next chunk for natural flow
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Move to next chunk
        await MainActor.run {
            currentChunkIndex += 1
        }
        
        // Play next chunk if available
        guard let provider = await MainActor.run(body: { chunkProvider }),
              let language = await MainActor.run(body: { currentLanguageCode }) else {
            return
        }
        
        // Continue with next chunk
        do {
            try await playNextChunk(originalText: await MainActor.run(body: { textChunks.joined(separator: " ") }), detectedLanguage: language, provider: provider)
        } catch {
            // Handle error silently or propagate
            await MainActor.run {
                textChunks = []
                currentChunkIndex = 0
                currentLanguageCode = nil
                currentLocaleCode = nil
                chunkProvider = nil
                currentChunkFinished = false
                isPlaying = false
            }
        }
    }
    
    // MARK: - Text Preprocessing
    
    private func preprocessTextForTTS(_ text: String) -> String {
        var processedText = text
        
        // Remove underscores (commonly used for blanks in quizzes)
        processedText = processedText.replacingOccurrences(of: "_", with: "")
        
        // Remove multiple consecutive underscores
        processedText = processedText.replacingOccurrences(of: "___+", with: "", options: .regularExpression)
        
        // Remove other non-speech characters that might interfere with TTS
        processedText = processedText.replacingOccurrences(of: "[", with: "")
        processedText = processedText.replacingOccurrences(of: "]", with: "")
        processedText = processedText.replacingOccurrences(of: "(", with: "")
        processedText = processedText.replacingOccurrences(of: ")", with: "")
        
        // Clean up extra spaces that might have been created
        processedText = processedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return processedText
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

        // Resume if paused
        if await MainActor.run(body: { isPaused }) && synthesizer.isPaused {
            synthesizer.continueSpeaking()
            await MainActor.run {
                isPlaying = true
            }
        } else {
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
            // Resume if paused and player exists for same URL
            if isPaused, let existingPlayer = player, existingPlayer.url == url {
                existingPlayer.play()
                isPlaying = true
            } else {
                // Create new player
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
            }
        } catch {
            isPlaying = false
            logError("Cannot play audio file: \(error), url: \(url)")
            throw CoreError.internalError(.cannotPlayAudio)
        }
    }

    func pause() {
        Task { @MainActor in
            // Pause but keep chunk state for resume
            player?.pause()
            speechSynthesizer?.pauseSpeaking(at: .immediate)
            isPlaying = false
            isPaused = true
            // Keep currentPlayingChunk so highlight remains visible when paused
        }
    }
    
    func resume() async throws {
        guard isPaused else {
            // Not in paused state - start new playback
            throw CoreError.internalError(.cannotSetupAudioSession)
        }

        await MainActor.run {
            isPaused = false
            isPlaying = true
        }

        // Resume the current player if it exists
        if let existingPlayer = player {
            existingPlayer.play()
        } else if let synthesizer = speechSynthesizer, synthesizer.isPaused {
            synthesizer.continueSpeaking()
        } else if chunkProvider != nil {
            // Resume chunked playback from current chunk
            guard let provider = chunkProvider,
                  let language = currentLanguageCode,
                  let originalText = pausedOriginalText else {
                return
            }
            
            // Continue from current chunk
            try await playNextChunk(originalText: originalText, detectedLanguage: language, provider: provider)
        }
    }

    func stop() {
        Task { @MainActor in
            player?.stop()
            speechSynthesizer?.stopSpeaking(at: .immediate)
            isPlaying = false
            isPaused = false

            // Clear chunking state
            textChunks = []
            currentChunkIndex = 0
            currentLanguageCode = nil
            currentLocaleCode = nil
            chunkProvider = nil
            currentChunkFinished = false
            currentPlayingChunk = nil
            pausedOriginalText = nil
        }
    }
    
    // MARK: - Caching Methods
    
    private func generateCacheKey(text: String, language: String, provider: TTSProvider, voice: String?) -> String {
        let voicePart = voice != nil ? "_\(voice!)" : ""
        
        // Create a hash of the text to avoid filename length issues
        let textHash = text.data(using: .utf8)?.sha256Hash ?? UUID().uuidString
        let keyString = "\(provider.rawValue)_\(language)\(voicePart)_\(textHash)"
        
        // Ensure the key is not too long for filesystem (max 255 chars on most systems)
        if keyString.count > 200 {
            // If still too long, create a shorter hash
            let shortHash = keyString.data(using: .utf8)?.sha256Hash ?? UUID().uuidString
            return "tts_\(shortHash.prefix(50))"
        }
        
        return keyString
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
            // If chunking is in progress, mark current chunk as finished
            // Otherwise, set isPlaying to false for normal playback
            if chunkProvider != nil {
                currentChunkFinished = true
            } else {
                isPlaying = false
            }
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            // Stop chunking if there's an error
            textChunks = []
            currentChunkIndex = 0
            currentLanguageCode = nil
            currentLocaleCode = nil
            chunkProvider = nil
            currentChunkFinished = false
            currentPlayingChunk = nil
            isPlaying = false
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSPlayer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // If chunking is in progress, mark current chunk as finished
            // Otherwise, set isPlaying to false for normal playback
            if chunkProvider != nil {
                currentChunkFinished = true
            } else {
                isPlaying = false
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // Stop chunking if cancelled
            textChunks = []
            currentChunkIndex = 0
            currentLanguageCode = nil
            currentLocaleCode = nil
            chunkProvider = nil
            currentChunkFinished = false
            currentPlayingChunk = nil
            isPlaying = false
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            // Pause should stop chunking
            textChunks = []
            currentChunkIndex = 0
            currentLanguageCode = nil
            currentLocaleCode = nil
            chunkProvider = nil
            currentChunkFinished = false
            currentPlayingChunk = nil
            isPlaying = false
        }
    }
}

//
//  SongLessonInfoSheetViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
final class SongLessonInfoSheetViewModel: BaseViewModel {

    enum Input {
        case loadData
        case generateHook
        case toggleFavorite
    }

    let song: Song

    @Published private(set) var preListenHook: PreListenHook?
    @Published private(set) var isGenerating = true
    @Published private(set) var lessonExists = false
    @Published private(set) var isFavorite = false
    @Published private(set) var lyrics: SongLyrics? // Expose lyrics so they can be passed to SongPlayerView
    @Published private(set) var lyricsError: Bool = false // Track if lyrics failed to load
    @Published private(set) var requiresPremium: Bool = false // Track if premium is required

    private let lyricsService = LRCLibService.shared
    private let lessonService = MusicLessonService.shared
    private let recommendationService = MusicRecommendationService.shared
    private let sessionService = SongLessonSessionService.shared

    // UserDefaults key for local hook caching
    private var hookCacheKey: String {
        "hook_\(song.id)"
    }

    init(song: Song) {
        self.song = song
        super.init()
    }

    func handle(_ input: Input) {
        switch input {
        case .loadData:
            checkLessonExists()
            checkFavoriteStatus()
            generateHook()
        case .generateHook:
            generateHook()
        case .toggleFavorite:
            toggleFavorite()
        }
    }

    private func checkLessonExists() {
        Task {
            if let session = SongLessonSessionService.shared.getSession(by: self.song.id) {
                await MainActor.run {
                    lessonExists = true
                }
            }
        }
    }

    private func checkFavoriteStatus() {
        Task {
            if let session = SongLessonSessionService.shared.getSession(by: self.song.id) {
                await MainActor.run {
                    isFavorite = session.isFavorite
                }
            }
        }
    }

    private func toggleFavorite() {
        Task {
            do {
                try await Task.detached {
                    try SongLessonSessionService.shared.toggleFavorite(song: self.song)
                }.value

                await MainActor.run {
                    isFavorite.toggle()
                }
                print("✅ [SongLessonInfoSheetViewModel] Toggled favorite: \(isFavorite)")
            } catch {
                print("❌ [SongLessonInfoSheetViewModel] Failed to toggle favorite: \(error)")
            }
        }
    }

    private func generateHook() {
        Task {
            // Check if user can make AI requests first (before loading lyrics)
            guard AIService.shared.canMakeAIRequest() else {
                await MainActor.run {
                    self.requiresPremium = true
                    self.isGenerating = false
                }
                print("⚠️ [SongLessonInfoSheetViewModel] Premium required for music lessons")
                return
            }

            // Check local cache first
            if let cachedHook = loadCachedHook() {
                print("✅ [SongLessonInfoSheetViewModel] Loaded hook from local cache")
                await MainActor.run {
                    self.preListenHook = cachedHook
                    self.isGenerating = false
                }
                return
            }

            do {
                // Get lyrics first
                let lyrics = try await lyricsService.getLyrics(
                    trackName: song.title,
                    artistName: song.artist,
                    albumName: song.album,
                    duration: song.duration
                )

                // Check if lyrics are available
                let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics ?? ""

                guard !lyricsText.isEmpty else {
                    await MainActor.run {
                        self.lyricsError = true
                        self.isGenerating = false
                    }
                    print("❌ [SongLessonInfoSheetViewModel] No lyrics available for this song")
                    return
                }

                guard let userProfile = OnboardingService.shared.userProfile,
                      let firstStudyLanguage = userProfile.studyLanguages.first else {
                    await MainActor.run {
                        isGenerating = false
                    }
                    return
                }

                // Store lyrics for later use
                await MainActor.run {
                    self.lyrics = lyrics
                }

                // Detect language from lyrics using LanguageDetector
                let detectedLanguage = LanguageDetector.shared.detectLanguage(for: lyricsText)
                print("🌍 [SongLessonInfoSheetViewModel] Detected language from lyrics: \(detectedLanguage.englishName)")

                // Use detected language as target language for hook/lesson generation
                // This ensures English songs get English lessons, Spanish songs get Spanish lessons, etc.
                // The hook explanations will be in the user's locale language
                let targetLanguage = detectedLanguage

                // Generate hook and determine song's CEFR level
                let (preListenHookResult, songCEFR) = try await lessonService.generatePreListenHook(
                    for: song,
                    lyrics: lyricsText,
                    targetLanguage: targetLanguage
                )

                // Save hook to local cache
                saveCachedHook(preListenHookResult)
                print("✅ [SongLessonInfoSheetViewModel] Saved hook to local cache")

                await MainActor.run {
                    self.preListenHook = preListenHookResult
                    self.isGenerating = false
                }
            } catch {
                print("❌ [SongLessonInfoSheetViewModel] Failed to generate hook: \(error)")
                await MainActor.run {
                    self.lyricsError = true
                    self.isGenerating = false
                }
            }
        }
    }

    // MARK: - Local Caching

    /// Load cached hook from UserDefaults
    /// - Returns: Cached PreListenHook if available
    /// - Note: Hooks are NEVER deleted or expired. They are generated per-user based on device locale
    ///         and persist indefinitely in UserDefaults.
    private func loadCachedHook() -> PreListenHook? {
        guard let data = UserDefaults.standard.data(forKey: hookCacheKey) else {
            return nil
        }
        return try? JSONDecoder().decode(PreListenHook.self, from: data)
    }

    /// Save hook to UserDefaults for permanent local storage
    /// - Parameter hook: PreListenHook to cache
    /// - Note: This cache is PERMANENT and separate from recommendations cache.
    ///         It will never be expired or deleted automatically.
    private func saveCachedHook(_ hook: PreListenHook) {
        guard let data = try? JSONEncoder().encode(hook) else {
            return
        }
        UserDefaults.standard.set(data, forKey: hookCacheKey)

        // Ensure UserDefaults is synced to disk
        UserDefaults.standard.synchronize()
        print("💾 [SongLessonInfoSheetViewModel] Hook permanently cached to UserDefaults")
    }
}

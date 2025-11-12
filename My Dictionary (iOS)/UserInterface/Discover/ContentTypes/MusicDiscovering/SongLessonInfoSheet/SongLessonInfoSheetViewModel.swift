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

    enum HookState: Hashable {
        case loaded(SongLyrics, PreListenHook)
        case failed(MusicError)
        case loading
    }

    @Published private(set) var song: Song
    @Published private(set) var isFavorite = false
    @Published private(set) var hookState: HookState = .loading

    private let lyricsService = LRCLibService.shared
    private let lessonService = MusicLessonService.shared
    private let recommendationService = MusicRecommendationService.shared
    private let sessionService = SongLessonSessionService.shared
    private let analytics = AnalyticsService.shared

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
            checkFavoriteStatus()
            generateHook()
        case .generateHook:
            generateHook()
        case .toggleFavorite:
            toggleFavorite()
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
                    try await SongLessonSessionService.shared.toggleFavorite(song: self.song)
                }.value

                await MainActor.run {
                    isFavorite.toggle()
                    analytics.logEvent(
                        .musicDiscoveringFavoriteToggled,
                        parameters: [
                            "song_id": song.serviceId,
                            "is_favorite": isFavorite ? 1 : 0
                        ]
                    )
                }
                logInfo("[SongLessonInfoSheetViewModel] Toggled favorite: \(isFavorite)")
            } catch {
                logError("[SongLessonInfoSheetViewModel] Failed to toggle favorite: \(error)")
            }
        }
    }

    private func generateHook() {
        Task {
            do {
                // Check if user can make AI requests first (before loading lyrics)
                guard AIService.shared.canMakeAIRequest() else {
                    await MainActor.run {
                        self.hookState = .failed(.premiumRequired)
                    }
                    logWarning("[SongLessonInfoSheetViewModel] Premium required for music lessons")
                    analytics.logEvent(
                        .musicDiscoveringHookFailed,
                        parameters: baseHookParameters().merging([
                            "reason": "premium_required"
                        ]) { _, new in new }
                    )
                    return
                }

                // Get lyrics first
                let lyrics = try await lyricsService.getLyrics(
                    trackName: song.title,
                    artistName: song.artist,
                    albumName: song.album,
                    duration: song.duration
                )

                // Check if lyrics are available
                let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics

                guard let lyricsText = lyricsText?.nilIfEmpty else {
                    await MainActor.run {
                        self.hookState = .failed(.lyricsNotFound)
                    }
                    logError("[SongLessonInfoSheetViewModel] No lyrics available for this song")
                    analytics.logEvent(
                        .musicDiscoveringHookFailed,
                        parameters: baseHookParameters().merging([
                            "reason": "lyrics_not_found"
                        ]) { _, new in new }
                    )
                    return
                }

                // Check local cache first
                if let cachedHook = loadCachedHook() {
                    logInfo("[SongLessonInfoSheetViewModel] Loaded hook from local cache")
                    await MainActor.run {
                        song.cefrLevel = cachedHook.songCEFRLevel
                        self.hookState = .loaded(lyrics, cachedHook)
                    }
                    analytics.logEvent(
                        .musicDiscoveringHookGenerated,
                        parameters: baseHookParameters().merging([
                            "source": "cache",
                            "cefr_level": cachedHook.songCEFRLevel.rawValue
                        ]) { _, new in new }
                    )
                    return
                }

                guard OnboardingService.shared.userProfile != nil else {
                    await MainActor.run {
                        self.hookState = .failed(.userProfileNotCompleted)
                    }
                    analytics.logEvent(
                        .musicDiscoveringHookFailed,
                        parameters: baseHookParameters().merging([
                            "reason": "profile_incomplete"
                        ]) { _, new in new }
                    )
                    return
                }

                // Get language from lyrics
                guard let targetLanguage = lyrics.detectedLanguage else {
                    logError("[SongLessonInfoSheetViewModel] Could not detect language in lyrics")
                    await MainActor.run {
                        self.hookState = .failed(.lyricsLanguageNotDetermined)
                    }
                    analytics.logEvent(
                        .musicDiscoveringHookFailed,
                        parameters: baseHookParameters().merging([
                            "reason": "language_detection_failed"
                        ]) { _, new in new }
                    )
                    return
                }
                logInfo("[SongLessonInfoSheetViewModel] Detected language from lyrics: \(targetLanguage.englishName)")

                // Generate hook and determine song's CEFR level
                let preListenHook = try await lessonService.generatePreListenHook(
                    for: song,
                    lyrics: lyricsText,
                    targetLanguage: targetLanguage
                )
                song.cefrLevel = preListenHook.songCEFRLevel
                // Save hook to local cache
                saveCachedHook(preListenHook)
                logInfo("[SongLessonInfoSheetViewModel] Saved hook to local cache")

                analytics.logEvent(
                    .musicDiscoveringHookGenerated,
                    parameters: baseHookParameters().merging([
                        "source": "network",
                        "cefr_level": preListenHook.songCEFRLevel.rawValue,
                        "detected_language": targetLanguage.rawValue
                    ]) { _, new in new }
                )

                await MainActor.run {
                    self.hookState = .loaded(lyrics, preListenHook)
                }
            } catch {
                logError("[SongLessonInfoSheetViewModel] Failed to generate hook: \(error)")
                await MainActor.run {
                    self.hookState = .failed(.hookGenerationFailed)
                }
                analytics.logEvent(
                    .musicDiscoveringHookFailed,
                    parameters: baseHookParameters().merging([
                        "reason": "hook_generation_failed",
                        "error_message": error.localizedDescription
                    ]) { _, new in new }
                )
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
        logInfo("[SongLessonInfoSheetViewModel] Hook permanently cached to UserDefaults")
    }
}

private extension SongLessonInfoSheetViewModel {
    func baseHookParameters() -> [String: Any] {
        var params: [String: Any] = [
            "song_id": song.serviceId
        ]

        if let cefr = song.cefrLevel?.rawValue {
            params["cefr_level"] = cefr
        }

        params["is_favorite"] = isFavorite ? 1 : 0

        return params
    }
}

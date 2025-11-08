//
//  MusicDiscoveringViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class MusicDiscoveringViewModel: BaseViewModel {

    enum LoadingStatus: Hashable {
        case idle
        case loadingSuggestions
        case loadingHistory
        case ready
        case error(String)
    }
    
    enum Input {
        case loadData
        case loadIncompleteSessions
        case loadCompletedSessions
        case loadFavoriteSongs
        case searchAppleMusic(query: String)
        case filterSectionsBySearch(query: String)
        case clearSearch
        case loadSuggestions
        case loadHistory
        case clearCache
        case reset
    }

    @Published private(set) var loadingStatus: LoadingStatus = .idle
    @Published private(set) var recommendationSongs: [Song] = []
    @Published private(set) var songTags: [String: SongTag] = [:]
    @Published private(set) var songGenerationCounts: [String: Int] = [:]
    @Published private(set) var listeningHistory: [MusicListeningHistory] = []
    
    // Song lesson sessions
    @Published private(set) var incompleteSessions: [CDSongLessonSession] = []
    @Published private(set) var completedSessions: [CDSongLessonSession] = []
    @Published private(set) var favoriteSongs: [CDSongLessonSession] = []
    
    // Search state
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published private(set) var searchResults: [Song] = []

    private let appleMusicService = AppleMusicService.shared
    private let aiService = AIService.shared
    private let onboardingService = OnboardingService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let recommendationService = MusicRecommendationService.shared
    private let songLessonSessionService = SongLessonSessionService.shared
    
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours (1 day)

    override init() {
        super.init()
        setupNotificationObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionDataChanged),
            name: .songSessionDidChange,
            object: nil
        )
    }
    
    @objc private func handleSessionDataChanged() {
        Task { @MainActor in
            // Reload sessions data when favorites or history changes
            loadIncompleteSessions()
            loadCompletedSessions()
            loadFavoriteSongs()
            print("🔄 [MusicDiscoveringViewModel] Reloaded sessions after change notification")
        }
    }

    // MARK: - Input Handler
    
    func handle(_ input: Input) {
        switch input {
        case .loadData:
            loadData()
        case .loadIncompleteSessions:
            loadIncompleteSessions()
        case .loadCompletedSessions:
            loadCompletedSessions()
        case .loadFavoriteSongs:
            loadFavoriteSongs()
        case .searchAppleMusic(let query):
            Task {
                await searchAppleMusic(query: query)
            }
        case .filterSectionsBySearch(let query):
            filterSectionsBySearch(query: query)
        case .clearSearch:
            clearSearch()
        case .loadSuggestions:
            loadSuggestions()
        case .loadHistory:
            loadHistory()
        case .clearCache:
            clearCache()
        case .reset:
            reset()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadSuggestions()
        loadHistory()
        loadIncompleteSessions()
        loadCompletedSessions()
        loadFavoriteSongs()
    }
    
    // MARK: - Session Loading
    
    private func loadIncompleteSessions() {
        Task {
            let sessions = await Task.detached {
                return SongLessonSessionService.shared.getIncompleteSessions()
            }.value
            
            await MainActor.run {
                self.incompleteSessions = sessions
            }
        }
    }
    
    private func loadCompletedSessions() {
        Task {
            let sessions = await Task.detached {
                return SongLessonSessionService.shared.getCompletedSessions()
            }.value
            
            await MainActor.run {
                self.completedSessions = sessions
            }
        }
    }
    
    private func loadFavoriteSongs() {
        Task {
            let sessions = await Task.detached {
                return SongLessonSessionService.shared.getFavoriteSongs()
            }.value
            
            await MainActor.run {
                self.favoriteSongs = sessions
            }
        }
    }
    
    // MARK: - Search
    
    private func searchAppleMusic(query: String) async {
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.isSearching = false
            }
            return
        }
        
        guard appleMusicService.isAuthorized else {
            await MainActor.run {
                self.isSearching = false
            }
            return
        }
        
        await MainActor.run {
            self.isSearching = true
        }
        
        do {
            let songs = try await appleMusicService.searchSongs(query: query, language: nil)
            await MainActor.run {
                self.searchResults = songs
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorReceived(error)
                self.searchResults = []
                self.isSearching = false
            }
        }
    }
    
    private func filterSectionsBySearch(query: String) {
        Task {
            await searchAppleMusic(query: query)
        }
    }
    
    private func clearSearch() {
        searchResults = []
        isSearching = false
    }

    private func loadSuggestions() {
        guard loadingStatus != .loadingSuggestions else { return }
        
        guard appleMusicService.isAuthorized else {
            loadingStatus = .idle
            return
        }
        
        // Only show loading state if we don't have any recommendations yet
        let shouldShowLoading = recommendationSongs.isEmpty
        
        if shouldShowLoading {
            loadingStatus = .loadingSuggestions
        }

        Task {
            do {
                try await generateRecommendations()
                
                await MainActor.run {
                    self.loadingStatus = .ready
                }
            } catch {
                await MainActor.run {
                    errorReceived(error)
                    self.loadingStatus = .error(error.localizedDescription)
                }
            }
        }
    }

    private func loadHistory() {
        Task {
            let history = await historyService.getHistory()
            await MainActor.run {
                self.listeningHistory = history
            }
        }
    }

    // MARK: - Recommendations Generation
    
    /// Generate recommendations with all CEFR levels (2 random songs per level, 12 total)
    /// Gets from UserDefaults cache first, then Firestore, then generates with AI
    private func generateRecommendations() async throws {
        guard let userProfile = onboardingService.userProfile,
              let firstStudyLanguage = userProfile.studyLanguages.first else {
            print("⚠️ [MusicDiscoveringViewModel] No user profile or study language")
            return
        }
        
        let language = firstStudyLanguage.language
        
        print("🔍 [MusicDiscoveringViewModel] Generating recommendations for all CEFR levels in \(language.englishName)")

        // Check UserDefaults cache first
        if let cachedSongs = getCachedSongs(), !isCacheExpired() {
            print("✅ [MusicDiscoveringViewModel] Using cached songs from UserDefaults (instant load)")
            
            // Use cached Song objects directly - no need to search Apple Music again!
            await MainActor.run {
                self.recommendationSongs = cachedSongs
            }
            
            return
        }
        
        print("📥 [MusicDiscoveringViewModel] Cache miss or expired, fetching fresh recommendations...")

        // Get recommendations for all CEFR levels (2 per level, 12 total)
        // This will try Firestore first, then OpenAI if needed
        do {
            let recommendationSongs = try await recommendationService.getAllLevelRecommendations(
                language: language,
                userProfile: userProfile
            )
            
            print("✅ [MusicDiscoveringViewModel] Got \(recommendationSongs.count) recommendations from all levels")
            
            // Convert RecommendationSong to Song objects with artwork
            var songsWithArtwork: [Song] = []
            
            for songRec in recommendationSongs {
                do {
                    let query = "\(songRec.artist) \(songRec.title)"
                    let songs = try await appleMusicService.searchSongs(query: query, language: nil)
                    
                    // Take the first result from Apple Music search
                    if let foundSong = songs.first {
                        // Create Song with CEFR level from recommendation
                        let songWithCEFR = Song(
                            id: foundSong.id,
                            title: foundSong.title,
                            artist: foundSong.artist,
                            album: foundSong.album,
                            albumArtURL: foundSong.albumArtURL,
                            duration: foundSong.duration,
                            serviceId: foundSong.serviceId,
                            cefrLevel: songRec.cefrLevel
                        )
                        songsWithArtwork.append(songWithCEFR)
                    } else {
                        print("⚠️ [MusicDiscoveringViewModel] No results found for \(songRec.artist) - \(songRec.title), skipping")
                    }
                } catch {
                    print("⚠️ [MusicDiscoveringViewModel] Failed to search Apple Music for \(songRec.title): \(error.localizedDescription)")
                    continue
                }
            }
            
            // Update recommendationSongs for UI
            await MainActor.run {
                self.recommendationSongs = songsWithArtwork
            }
            
            // Cache the complete Song objects (with artwork) in UserDefaults
            saveCachedSongs(songsWithArtwork)
        } catch {
            print("❌ [MusicDiscoveringViewModel] Failed to generate recommendations: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Caching
    
    /// Get cached complete Song objects from UserDefaults
    private func getCachedSongs() -> [Song]? {
        guard let cacheData = UDService.musicSuggestionsCacheData else {
            print("ℹ️ [MusicDiscoveringViewModel] No cache data found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let songs = try decoder.decode([Song].self, from: cacheData)
            print("✅ [MusicDiscoveringViewModel] Loaded \(songs.count) cached songs with artwork")
            return songs
        } catch {
            print("⚠️ [MusicDiscoveringViewModel] Failed to decode cached songs: \(error)")
            return nil
        }
    }
    
    /// Save complete Song objects (with artwork) to UserDefaults cache
    private func saveCachedSongs(_ songs: [Song]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(songs)
            UDService.musicSuggestionsCacheData = data
            UDService.musicSuggestionsCacheTimestamp = Date()
            print("💾 [MusicDiscoveringViewModel] Cached \(songs.count) complete songs (with artwork) to UserDefaults")
        } catch {
            print("⚠️ [MusicDiscoveringViewModel] Failed to cache songs: \(error)")
        }
    }
    
    /// Check if cache is expired (24 hours)
    private func isCacheExpired() -> Bool {
        guard let timestamp = UDService.musicSuggestionsCacheTimestamp else {
            return true
        }
        
        let elapsed = Date().timeIntervalSince(timestamp)
        let isExpired = elapsed > cacheDuration
        
        if isExpired {
            print("⏰ [MusicDiscoveringViewModel] Cache expired (age: \(Int(elapsed/3600)) hours)")
        } else {
            print("✅ [MusicDiscoveringViewModel] Cache still valid (age: \(Int(elapsed/3600)) hours)")
        }
        
        return isExpired
    }
    
    private func clearCache() {
        UDService.musicSuggestionsCacheData = nil
        UDService.musicSuggestionsCacheTimestamp = nil
        print("🗑️ [MusicDiscoveringViewModel] Cache cleared")
    }
    
    private func reset() {
        searchResults = []
        searchText = ""
        isSearching = false
        
        clearCache()
        loadData()
    }
}

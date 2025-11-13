//
//  MusicDiscoveringMacViewModel.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import Foundation
import Combine

@MainActor
final class MusicDiscoveringMacViewModel: BaseViewModel {

    enum LoadingStatus: Hashable {
        case idle
        case loadingSuggestions
        case loadingHistory
        case ready
        case error(String)
    }
    
    enum RecommendationPhase: Hashable {
        case idle
        case loadingRecommendations
        case generatingRecommendations
        case loadingAppleMusic
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
        case selectRecommendationLanguage(InputLanguage)
    }

    @Published private(set) var loadingStatus: LoadingStatus = .idle
    @Published private(set) var recommendationSongs: [Song] = []
    @Published private(set) var recommendationPhase: RecommendationPhase = .idle
    @Published private(set) var listeningHistory: [MusicListeningHistory] = []
    @Published private(set) var studyLanguages: [StudyLanguage] = []
    @Published private(set) var activeRecommendationLanguage: InputLanguage?
    
    @Published private(set) var incompleteSessions: [CDSongLessonSession] = []
    @Published private(set) var completedSessions: [CDSongLessonSession] = []
    @Published private(set) var favoriteSongs: [CDSongLessonSession] = []
    
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published private(set) var searchResults: [Song] = []

    private let appleMusicService = AppleMusicService.shared
    private let aiService = AIService.shared
    private let onboardingService = OnboardingService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let recommendationService = MusicRecommendationService.shared
    private let songLessonSessionService = SongLessonSessionService.shared
    private let analytics = AnalyticsService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private let cacheDuration: TimeInterval = 24 * 60 * 60
    private var lastSearchQuery: String?

    override init() {
        super.init()
        setupNotificationObserver()
        setupProfileObserver()
        updateStudyLanguages(from: onboardingService.userProfile)
    }
    
    var recommendationStatusMessage: String? {
        switch recommendationPhase {
        case .idle:
            return nil
        case .loadingRecommendations:
            return Loc.MusicDiscovering.Status.Recommendations.loading
        case .generatingRecommendations:
            return Loc.MusicDiscovering.Status.Recommendations.generating
        case .loadingAppleMusic:
            return Loc.MusicDiscovering.Status.Recommendations.fetchingData
        }
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
            loadIncompleteSessions()
            loadCompletedSessions()
            loadFavoriteSongs()
        }
    }

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
        case .selectRecommendationLanguage(let language):
            updateActiveRecommendationLanguage(language)
        }
    }
    
    private func loadData() {
        updateStudyLanguages(from: onboardingService.userProfile)
        loadSuggestions()
        loadHistory()
        loadIncompleteSessions()
        loadCompletedSessions()
        loadFavoriteSongs()
    }
    
    private func loadIncompleteSessions() {
        Task {
            let sessions = await Task.detached {
                SongLessonSessionService.shared.getIncompleteSessions()
            }.value
            
            await MainActor.run {
                self.incompleteSessions = sessions
            }
        }
    }
    
    private func loadCompletedSessions() {
        Task {
            let sessions = await Task.detached {
                SongLessonSessionService.shared.getCompletedSessions()
            }.value
            
            await MainActor.run {
                self.completedSessions = sessions
            }
        }
    }
    
    private func loadFavoriteSongs() {
        Task {
            let sessions = await Task.detached {
                SongLessonSessionService.shared.getFavoriteSongs()
            }.value
            
            await MainActor.run {
                self.favoriteSongs = sessions
            }
        }
    }
    
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
            analytics.logEvent(
                .musicDiscoveringSearchFailed,
                parameters: baseAnalyticsParameters().merging([
                    "query_length": query.count,
                    "reason": "unauthorized"
                ]) { _, new in new }
            )
            return
        }
        
        await MainActor.run {
            self.isSearching = true
        }
        
        let isRepeat = lastSearchQuery == query
        analytics.logEvent(
            .musicDiscoveringSearchRequested,
            parameters: baseAnalyticsParameters().merging([
                "query_length": query.count,
                "is_repeat": isRepeat ? 1 : 0
            ]) { _, new in new }
        )
        lastSearchQuery = query
        
        do {
            let songs = try await appleMusicService.searchSongs(query: query)
            await MainActor.run {
                self.searchResults = songs
                self.isSearching = false
            }
            analytics.logEvent(
                .musicDiscoveringSearchResults,
                parameters: baseAnalyticsParameters().merging([
                    "query_length": query.count,
                    "result_count": songs.count,
                    "is_repeat": isRepeat ? 1 : 0
                ]) { _, new in new }
            )
        } catch {
            await MainActor.run {
                self.errorReceived(error)
                self.searchResults = []
                self.isSearching = false
            }
            analytics.logEvent(
                .musicDiscoveringSearchFailed,
                parameters: baseAnalyticsParameters().merging([
                    "query_length": query.count,
                    "is_repeat": isRepeat ? 1 : 0,
                    "reason": "error",
                    "error_message": error.localizedDescription
                ]) { _, new in new }
            )
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

    private func loadSuggestions(for languageOverride: InputLanguage? = nil) {
        guard loadingStatus != .loadingSuggestions else { return }
        
        guard appleMusicService.isAuthorized else {
            loadingStatus = .idle
            recommendationPhase = .idle
            analytics.logEvent(
                .musicDiscoveringRecommendationsFailed,
                parameters: baseAnalyticsParameters().merging([
                    "reason": "unauthorized"
                ]) { _, new in new }
            )
            return
        }
        
        let targetLanguage = languageOverride ?? activeRecommendationLanguage
        
        if targetLanguage == nil {
            updateStudyLanguages(from: onboardingService.userProfile)
        }
        
        guard let languageToLoad = targetLanguage ?? activeRecommendationLanguage else {
            recommendationSongs = []
            loadingStatus = .idle
            recommendationPhase = .idle
            analytics.logEvent(
                .musicDiscoveringRecommendationsFailed,
                parameters: baseAnalyticsParameters().merging([
                    "reason": "no_language"
                ]) { _, new in new }
            )
            return
        }
        
        let shouldShowLoading = recommendationSongs.isEmpty
        
        if shouldShowLoading {
            loadingStatus = .loadingSuggestions
        }

        analytics.logEvent(
            .musicDiscoveringRecommendationsRequested,
            parameters: baseAnalyticsParameters(language: languageToLoad).merging([
                "trigger": languageOverride == nil ? "auto" : "manual"
            ]) { _, new in new }
        )

        Task {
            do {
                try await generateRecommendations(for: languageToLoad)
                
                await MainActor.run {
                    self.loadingStatus = .ready
                }
            } catch {
                await MainActor.run {
                    self.errorReceived(error)
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

    private func generateRecommendations(for language: InputLanguage) async throws {
        let requestStart = Date()

        guard let userProfile = onboardingService.userProfile else {
            recommendationPhase = .idle
            analytics.logEvent(
                .musicDiscoveringRecommendationsFailed,
                parameters: baseAnalyticsParameters(language: language).merging([
                    "reason": "missing_profile"
                ]) { _, new in new }
            )
            return
        }
        
        guard userProfile.studyLanguages.contains(where: { $0.language == language }) else {
            recommendationPhase = .idle
            analytics.logEvent(
                .musicDiscoveringRecommendationsFailed,
                parameters: baseAnalyticsParameters(language: language).merging([
                    "reason": "language_not_in_profile"
                ]) { _, new in new }
            )
            return
        }
        
        if let cachedSongs = getCachedSongs(for: language), !isCacheExpired(for: language) {
            await MainActor.run {
                self.recommendationPhase = .idle
                self.recommendationSongs = cachedSongs
            }
            
            analytics.logEvent(
                .musicDiscoveringRecommendationsReceived,
                parameters: baseAnalyticsParameters(language: language).merging([
                    "count": cachedSongs.count,
                    "filtered_count": cachedSongs.count,
                    "source": "cache",
                    "duration_ms": Int(Date().timeIntervalSince(requestStart) * 1000)
                ]) { _, new in new }
            )
            return
        }
        
        recommendationPhase = .loadingRecommendations

        do {
            let recommendationSongs = try await recommendationService.getAllLevelRecommendations(
                language: language,
                userProfile: userProfile,
                statusHandler: { [weak self] phase in
                    Task { @MainActor in
                        guard let self else { return }
                        switch phase {
                        case .checkingCache:
                            self.recommendationPhase = .loadingRecommendations
                        case .generatingWithAI:
                            self.recommendationPhase = .generatingRecommendations
                        }
                    }
                }
            )
            
            let listeningHistory = await historyService.getHistory()
            let completedHistory = listeningHistory.filter { $0.completed }
            let completedAppleMusicIds = Set(completedHistory.map { $0.song.serviceId }.filter { !$0.isEmpty })
            let completedTitleArtistPairs = Set(completedHistory.map {
                [$0.song.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current),
                 $0.song.artist.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)].joined(separator: "|")
            })
            
            let filteredRecommendations = recommendationSongs.filter { recommendation in
                if let appleMusicId = recommendation.appleMusicId, completedAppleMusicIds.contains(appleMusicId) {
                    return false
                }
                
                let normalizedTitle = recommendation.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                let normalizedArtist = recommendation.artist.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                return !completedTitleArtistPairs.contains([normalizedTitle, normalizedArtist].joined(separator: "|"))
            }
            
            let groupedByLevel = Dictionary(grouping: filteredRecommendations) { $0.cefrLevel }
            var prioritized: [RecommendationSong] = []
            var overflow: [RecommendationSong] = []
            
            for level in CEFRLevel.allCases {
                guard let songs = groupedByLevel[level], !songs.isEmpty else { continue }
                let shuffled = songs.shuffled()
                let primary = Array(shuffled.prefix(2))
                prioritized.append(contentsOf: primary)
                if shuffled.count > 2 {
                    overflow.append(contentsOf: shuffled.dropFirst(2))
                }
            }
            
            overflow.shuffle()
            let combined = prioritized + overflow
            let recommendationQueue = combined.isEmpty ? filteredRecommendations.shuffled() : combined
            let limitedQueue = Array(recommendationQueue.prefix(12))
            
            var songsWithArtwork: [Song] = []
            var seenSongs = Set<String>()
            
            recommendationPhase = .loadingAppleMusic
            
            for songRec in limitedQueue {
                let identity = "\(songRec.title.lowercased())-\(songRec.artist.lowercased())"
                if seenSongs.contains(identity) {
                    continue
                }
                do {
                    let query = "\(songRec.artist) \(songRec.title)"
                    let songs = try await appleMusicService.searchSongs(query: query)
                    
                    if let foundSong = songs.first {
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
                        seenSongs.insert(identity)
                    }
                } catch {
                    continue
                }
            }
            
            await MainActor.run {
                self.recommendationPhase = .idle
                self.recommendationSongs = songsWithArtwork
            }
            
            let duration = Date().timeIntervalSince(requestStart)
            let receivedCount = songsWithArtwork.count
            let filteredCount = filteredRecommendations.count

            if receivedCount == 0 {
                analytics.logEvent(
                    .musicDiscoveringRecommendationsEmpty,
                    parameters: baseAnalyticsParameters(language: language).merging([
                        "filtered_count": filteredCount,
                        "duration_ms": Int(duration * 1000)
                    ]) { _, new in new }
                )
            } else {
                analytics.logEvent(
                    .musicDiscoveringRecommendationsReceived,
                    parameters: baseAnalyticsParameters(language: language).merging([
                        "count": receivedCount,
                        "filtered_count": filteredCount,
                        "source": "network",
                        "duration_ms": Int(duration * 1000)
                    ]) { _, new in new }
                )
            }
            
            saveCachedSongs(songsWithArtwork, for: language)
        } catch {
            analytics.logEvent(
                .musicDiscoveringRecommendationsFailed,
                parameters: baseAnalyticsParameters(language: language).merging([
                    "reason": "generation_error",
                    "error_message": error.localizedDescription
                ]) { _, new in new }
            )
            throw error
        }
    }
    
    private func getCachedSongs(for language: InputLanguage) -> [Song]? {
        guard let cacheData = UDService.musicSuggestionsCacheData else {
            return nil
        }
        
        guard UDService.musicSuggestionsCacheLanguage == language.rawValue else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let songs = try decoder.decode([Song].self, from: cacheData)
            return songs
        } catch {
            return nil
        }
    }
    
    private func saveCachedSongs(_ songs: [Song], for language: InputLanguage) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(songs)
            UDService.musicSuggestionsCacheData = data
            UDService.musicSuggestionsCacheTimestamp = Date()
            UDService.musicSuggestionsCacheLanguage = language.rawValue
        } catch {
            logWarning("Failed to cache songs: \(error)")
        }
    }
    
    private func isCacheExpired(for language: InputLanguage) -> Bool {
        guard let timestamp = UDService.musicSuggestionsCacheTimestamp else {
            return true
        }
        
        if UDService.musicSuggestionsCacheLanguage != language.rawValue {
            return true
        }
        
        let elapsed = Date().timeIntervalSince(timestamp)
        return elapsed > cacheDuration
    }
    
    private func clearCache() {
        UDService.musicSuggestionsCacheData = nil
        UDService.musicSuggestionsCacheTimestamp = nil
        UDService.musicSuggestionsCacheLanguage = nil
    }
    
    private func reset() {
        searchResults = []
        searchText = ""
        isSearching = false
        
        clearCache()
        loadData()
    }
    
    private func setupProfileObserver() {
        onboardingService.$userProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.updateStudyLanguages(from: profile)
            }
            .store(in: &cancellables)
    }
    
    private func updateStudyLanguages(from profile: UserOnboardingProfile?) {
        let languages = profile?.studyLanguages ?? []
        studyLanguages = languages
        
        guard !languages.isEmpty else {
            activeRecommendationLanguage = nil
            recommendationSongs = []
            return
        }
        
        if let storedCode = UDService.musicRecommendationsSelectedLanguage,
           let stored = languages.first(where: { $0.language.rawValue == storedCode }) {
            updateActiveRecommendationLanguage(stored.language, refreshIfChanged: false)
        } else if let current = activeRecommendationLanguage,
                  languages.contains(where: { $0.language == current }) {
        } else if let first = languages.first?.language {
            updateActiveRecommendationLanguage(first, refreshIfChanged: false)
        }
    }
    
    private func updateActiveRecommendationLanguage(_ language: InputLanguage, refreshIfChanged: Bool = true) {
        guard activeRecommendationLanguage != language else { return }
        activeRecommendationLanguage = language
        UDService.musicRecommendationsSelectedLanguage = language.rawValue
        analytics.logEvent(
            .musicDiscoveringLanguageChanged,
            parameters: baseAnalyticsParameters(language: language)
        )
        
        if refreshIfChanged {
            clearCache()
            loadSuggestions(for: language)
        }
    }
}

private extension MusicDiscoveringMacViewModel {
    func baseAnalyticsParameters(language: InputLanguage? = nil) -> [String: Any] {
        var params: [String: Any] = [
            "authorized": appleMusicService.isAuthorized ? 1 : 0
        ]
        
        if let language {
            params["language_code"] = language.rawValue
        } else if let activeRecommendationLanguage {
            params["language_code"] = activeRecommendationLanguage.rawValue
        }
        
        return params
    }
}


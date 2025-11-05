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
        case generatingAI
        case ready
        case error(String)
    }

    @Published private(set) var loadingStatus: LoadingStatus = .idle
    @Published private(set) var suggestedSongs: [Song] = []
    @Published private(set) var dictionaryWordSongs: [Song] = []
    @Published private(set) var songTags: [String: SongTag] = [:]
    @Published private(set) var songGenerationCounts: [String: Int] = [:]
    @Published private(set) var listeningHistory: [MusicListeningHistory] = []
    @Published private(set) var currentSession: MusicDiscoveringSession?
    @Published private(set) var currentSong: Song?
    @Published private(set) var currentLyrics: SongLyrics?
    @Published private(set) var aiContent: MusicDiscoveringResponse?
    @Published private(set) var preListenHook: PreListenHook?
    @Published private(set) var adaptedLesson: AdaptedLesson?

    // AI loading states
    @Published var isLoadingExplanation = false
    @Published var isLoadingQuiz = false
    @Published var isLoadingVocabulary = false
    @Published var isLoadingPreListenHook = false

    private let appleMusicService = AppleMusicService.shared
    private let musicPlayerService = MusicPlayerService.shared
    private let lyricsService = LRCLibService.shared
    private let aiService = AIService.shared
    private let onboardingService = OnboardingService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let wordsProvider = WordsProvider.shared
    private let lessonService = MusicLessonService.shared
    private let recommendationEngine = MusicRecommendationEngine.shared
    private let songTagService = MusicSongTagService.shared
    
    private let cacheDuration: TimeInterval = 18 * 60 * 60 // 18 hours

    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupBindings()
        loadData()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Observe music player service
        musicPlayerService.$currentSong
            .assign(to: &$currentSong)

        musicPlayerService.$isPlaying
            .sink { [weak self] isPlaying in
                self?.updateSessionProgress()
            }
            .store(in: &cancellables)

        musicPlayerService.$currentTime
            .sink { [weak self] _ in
                self?.updateSessionProgress()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadData() {
        loadSuggestions()
        loadHistory()
    }

    func loadSuggestions() {
        guard loadingStatus != .loadingSuggestions else { return }
        
        // Check if Apple Music is authenticated
        guard appleMusicService.isAuthorized else {
            loadingStatus = .idle
            return
        }
        
        // Check cache first
        if let cachedSuggestions = getCachedSuggestions(), !isCacheExpired() {
            suggestedSongs = cachedSuggestions.suggestedSongs
            dictionaryWordSongs = cachedSuggestions.dictionaryWordSongs
            loadingStatus = .ready
            return
        }

        loadingStatus = .loadingSuggestions

        Task {
            do {
                async let personalizedSongs = generatePersonalizedSuggestions()
                async let dictionarySongs = generateDictionaryWordSuggestions()
                
                let (personalized, dictionary) = try await (personalizedSongs, dictionarySongs)
                
                await MainActor.run {
                    self.suggestedSongs = personalized
                    self.dictionaryWordSongs = dictionary
                    self.loadingStatus = .ready
                    
                    // Cache the suggestions
                    self.saveToCache(suggestedSongs: personalized, dictionaryWordSongs: dictionary)
                }
            } catch {
                await MainActor.run {
                    errorReceived(error)
                    self.loadingStatus = .error(error.localizedDescription)
                }
            }
        }
    }

    func loadHistory() {
        Task {
            let history = await historyService.getHistory()
            await MainActor.run {
                self.listeningHistory = history
            }
        }
    }

    // MARK: - Song Selection & Playback

    func selectSong(_ song: Song) async {
        // Stop current playback
        musicPlayerService.stop()

        currentSong = song

        // Set the queue to suggested songs for navigation
        let allSuggestedSongs = suggestedSongs + dictionaryWordSongs
        if let songIndex = allSuggestedSongs.firstIndex(where: { $0.id == song.id }) {
            await MainActor.run {
                musicPlayerService.setQueue(allSuggestedSongs, currentIndex: songIndex)
            }
        } else {
            // If song not in suggestions, create a single-item queue
            await MainActor.run {
                musicPlayerService.setQueue([song], currentIndex: 0)
            }
        }

        // Create or update session
        if var existingSession = currentSession, existingSession.song.id == song.id {
            // Update existing session
            existingSession.lastPlayedAt = Date()
            currentSession = existingSession
        } else {
            // Create new session
            let session = MusicDiscoveringSession(song: song)
            currentSession = session
        }

        // Load lyrics
        do {
            let lyrics = try await lyricsService.getLyrics(
                trackName: song.title,
                artistName: song.artist,
                albumName: song.album,
                duration: song.duration
            )
            await MainActor.run {
                self.currentLyrics = lyrics
            }
        } catch {
            // Lyrics not found - continue without lyrics
            await MainActor.run {
                self.currentLyrics = nil
            }
        }

        // Start playback
        do {
            try await musicPlayerService.play(song: song)
        } catch {
            await MainActor.run {
                errorReceived(error)
            }
        }

        // Save to history
        await historyService.addToHistory(song: song)
        loadHistory()
    }

    func playPause() {
        if musicPlayerService.isPlaying {
            musicPlayerService.pause()
        } else {
            musicPlayerService.play()
        }
    }

    func seek(to time: TimeInterval) {
        musicPlayerService.seek(to: time)
    }

    func updateCurrentSession(_ session: MusicDiscoveringSession? = nil) {
        self.currentSession = session
    }
    
    /// Update lyrics for the currently playing song without stopping playback
    func updateLyricsForCurrentSong() async {
        guard let song = currentSong else { return }
        
        // Load lyrics
        do {
            let lyrics = try await lyricsService.getLyrics(
                trackName: song.title,
                artistName: song.artist,
                albumName: song.album,
                duration: song.duration
            )
            await MainActor.run {
                self.currentLyrics = lyrics
            }
        } catch {
            // Lyrics not found - continue without lyrics
            await MainActor.run {
                self.currentLyrics = nil
            }
        }
        
        // Update session if needed
        if var session = currentSession, session.song.id != song.id {
            let newSession = MusicDiscoveringSession(song: song)
            currentSession = newSession
        } else if currentSession == nil {
            let session = MusicDiscoveringSession(song: song)
            currentSession = session
        }
    }

    // MARK: - AI Content Generation

    func generateExplanation() async {
        guard let song = currentSong,
              let lyrics = currentLyrics,
              lyrics.hasLyrics else {
            showAlert(withModel: .error(message: "Lyrics not available for explanation"))
            return
        }

        guard aiService.canMakeAIRequest() else {
            showAlert(withModel: .error(message: "AI features require Pro subscription"))
            return
        }

        isLoadingExplanation = true

        do {
            guard let userProfile = onboardingService.userProfile,
                  let firstStudyLanguage = userProfile.studyLanguages.first else {
                throw MusicError.authenticationRequired
            }

            // Get CEFR level from study language
            let cefrLevel = firstStudyLanguage.proficiencyLevel

            // Use MusicLessonService which checks Firestore cache first
            let adaptedLesson = try await lessonService.getLesson(
                for: song,
                lyrics: lyrics,
                userLevel: cefrLevel
            )

            // Convert to MusicDiscoveringResponse for UI
            let response = lessonService.convertToMusicDiscoveringResponse(adaptedLesson, song: song)

            await MainActor.run {
                self.adaptedLesson = adaptedLesson
                self.aiContent = response
                self.isLoadingExplanation = false

                // Mark explanation as requested in session
                if var session = self.currentSession {
                    session.markExplanationRequested()
                    self.currentSession = session
                }
            }
        } catch {
            await MainActor.run {
                self.errorReceived(error)
                self.isLoadingExplanation = false
            }
        }
    }

    func generateQuiz() async {
        guard let song = currentSong,
              let lyrics = currentLyrics,
              lyrics.hasLyrics else {
            showAlert(withModel: .error(message: "Lyrics not available for quiz"))
            return
        }

        guard aiService.canMakeAIRequest() else {
            showAlert(withModel: .error(message: "AI features require Pro subscription"))
            return
        }

        isLoadingQuiz = true

        do {
            guard let userProfile = onboardingService.userProfile,
                  let firstStudyLanguage = userProfile.studyLanguages.first else {
                throw MusicError.authenticationRequired
            }

            // Get CEFR level from study language
            let cefrLevel = firstStudyLanguage.proficiencyLevel

            // Use MusicLessonService which will use cached quiz template from Firestore
            let adaptedLesson = try await lessonService.getLesson(
                for: song,
                lyrics: lyrics,
                userLevel: cefrLevel
            )

            // Convert lesson to MusicDiscoveringResponse with quiz
            let response = lessonService.convertToMusicDiscoveringResponse(adaptedLesson, song: song)

            await MainActor.run {
                // Update AI content with quiz
                self.aiContent = response
                self.isLoadingQuiz = false

                // Mark quiz as requested in session
                if var session = self.currentSession {
                    session.hasCompletedQuiz = false
                    self.currentSession = session
                }
            }
        } catch {
            await MainActor.run {
                self.errorReceived(error)
                self.isLoadingQuiz = false
            }
        }
    }

    func extractVocabulary() {
        // Vocabulary is included in the full AI response
        // If explanation was generated, vocabulary should already be available
        if aiContent == nil {
            Task {
                await generateExplanation()
            }
        }
    }
    
    // MARK: - Pre-Listen Stage
    
    func generatePreListenHook() async {
        guard let song = currentSong,
              let lyrics = currentLyrics,
              lyrics.hasLyrics else {
            return
        }
        
        guard aiService.canMakeAIRequest() else {
            return
        }
        
        isLoadingPreListenHook = true
        
        do {
            guard let userProfile = onboardingService.userProfile,
                  let firstStudyLanguage = userProfile.studyLanguages.first else {
                throw MusicError.authenticationRequired
            }
            
            let cefrLevel = firstStudyLanguage.proficiencyLevel
            let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics ?? ""
            
            guard !lyricsText.isEmpty else {
                throw AIError.invalidResponse
            }
            
            let hook = try await lessonService.generatePreListenHook(
                for: song,
                lyrics: lyricsText,
                userLevel: cefrLevel
            )
            
            await MainActor.run {
                self.preListenHook = hook
                self.isLoadingPreListenHook = false
            }
        } catch {
            await MainActor.run {
                self.errorReceived(error)
                self.isLoadingPreListenHook = false
            }
        }
    }

    // MARK: - Session Management

    private func updateSessionProgress() {
        guard var session = currentSession else { return }

        let progress = musicPlayerService.currentTime
        session.updateProgress(progress)

        if musicPlayerService.isPlaying {
            let timeDelta = 0.1 // Approximate update interval
            session.addListeningTime(timeDelta)
        }

        currentSession = session
    }

    // MARK: - Suggestions Generation

    private func generatePersonalizedSuggestions() async throws -> [Song] {
        guard let userProfile = onboardingService.userProfile else {
            return []
        }
        
        // Check if Apple Music is authenticated
        guard appleMusicService.isAuthorized else {
            return []
        }
        
        // Get available songs from Apple Music (search for popular songs in user's study languages)
        let studyLanguages = userProfile.studyLanguages.map { $0.language.rawValue }
        var availableSongs: [Song] = []
        
        for language in studyLanguages {
            do {
                // Search for popular songs in the target language
                let songs = try await appleMusicService.searchSongs(
                    query: language,
                    language: language
                )
                availableSongs.append(contentsOf: songs)
            } catch {
                continue
            }
        }
        
        // Remove duplicates
        var uniqueSongs: [Song] = []
        var seenIds = Set<String>()
        
        for song in availableSongs {
            if !seenIds.contains(song.id) {
                uniqueSongs.append(song)
                seenIds.insert(song.id)
            }
        }
        
        // Load song tags from Firestore
        let uniqueSongsIds = uniqueSongs.map { $0.id }
        let songTags = await songTagService.getTags(for: uniqueSongsIds)

        // Use recommendation engine to score and rank songs
        let recommendedSongs = recommendationEngine.recommend(
            top: 20,
            userProfile: userProfile,
            availableSongs: uniqueSongs,
            songTags: songTags
        )
        
        // If no recommendations from engine, fallback to AI suggestions
        if recommendedSongs.isEmpty {
            return try await generatePersonalizedSuggestionsFallback()
        }
        
        // Load song tags and generation counts for recommended songs
        let recommendedSongsIds = recommendedSongs.map { $0.id }
        let tags = await songTagService.getTags(for: recommendedSongsIds)

        // Load generation counts in parallel
        var generationCounts: [String: Int] = [:]
        await withTaskGroup(of: (String, Int?).self) { group in
            for songId in uniqueSongsIds {
                group.addTask {
                    let count = await self.songTagService.getGenerationCount(for: songId)
                    return (songId, count)
                }
            }

            for songId in recommendedSongsIds {
                group.addTask {
                    let count = await self.songTagService.getGenerationCount(for: songId)
                    return (songId, count)
                }
            }
            
            for await (songId, count) in group {
                if let count = count {
                    generationCounts[songId] = count
                }
            }
        }
        
        await MainActor.run {
            self.songTags.merge(tags) { _, new in new }
            self.songGenerationCounts.merge(generationCounts) { _, new in new }
        }
        
        return recommendedSongs
    }
    
    private func generateDictionaryWordSuggestions() async throws -> [Song] {
        guard let userProfile = onboardingService.userProfile else {
            return []
        }

        // Check if AI service is available
        guard aiService.canMakeAIRequest() else {
            // Fallback to search-based approach if AI not available
            return try await generateDictionaryWordSuggestionsFallback()
        }
        
        // Check if Apple Music is authenticated
        guard appleMusicService.isAuthorized else {
            return []
        }
        
        // Get user's dictionary words
        let allWords = wordsProvider.words
        let targetLanguages = Set(userProfile.studyLanguages.map { $0.language.rawValue })
        let filteredWords = allWords.filter { word in
            guard let languageCode = word.languageCode else { return false }
            return targetLanguages.contains(languageCode)
        }
        
        guard !filteredWords.isEmpty else {
            return []
        }
        
        // Sort words by relevance
        let sortedWords = filteredWords.sorted { word1, word2 in
            let isFavorite1 = word1.isFavorite ? 1 : 0
            let isFavorite2 = word2.isFavorite ? 1 : 0
            if isFavorite1 != isFavorite2 {
                return isFavorite1 > isFavorite2
            }
            return word1.difficultyScore > word2.difficultyScore
        }
        
        let dictionaryWords = Array(sortedWords.prefix(30)).compactMap { $0.wordItself }
        
        // Request AI suggestions
        let aiResponse: AISongSuggestionsResponse = try await aiService.request(
            .musicSuggestions(
                userProfile: userProfile,
                dictionaryWords: dictionaryWords.isEmpty ? nil : dictionaryWords
            )
        )
        
        // Search Apple Music for AI-suggested dictionary word songs
        var foundSongs: [Song] = []
        
        for suggestion in aiResponse.dictionaryWordSongs {
            do {
                // Search for the specific song by title and artist
                let query = "\(suggestion.title) \(suggestion.artist)"
                let songs = try await appleMusicService.searchSongs(
                    query: query,
                    language: suggestion.language
                )
                // Try to find exact match first
                if let exactMatch = songs.first(where: { 
                    $0.title.lowercased().contains(suggestion.title.lowercased()) &&
                    $0.artist.lowercased().contains(suggestion.artist.lowercased())
                }) {
                    foundSongs.append(exactMatch)
                } else if let firstMatch = songs.first {
                    // If no exact match, use first result
                    foundSongs.append(firstMatch)
                }
            } catch {
                // Continue with other suggestions
                continue
            }
        }
        
        // Remove duplicates
        var uniqueSongs: [Song] = []
        var seenIds = Set<String>()
        
        for song in foundSongs {
            if !seenIds.contains(song.id) {
                uniqueSongs.append(song)
                seenIds.insert(song.id)
            }
        }
        
        let finalSongs = Array(uniqueSongs.prefix(20))
        
        // Load song tags and generation counts for dictionary word songs
        let songIds = finalSongs.map { $0.id }
        let tags = await songTagService.getTags(for: songIds)
        
        // Load generation counts in parallel
        var generationCounts: [String: Int] = [:]
        await withTaskGroup(of: (String, Int?).self) { group in
            for songId in songIds {
                group.addTask {
                    let count = await self.songTagService.getGenerationCount(for: songId)
                    return (songId, count)
                }
            }
            
            for await (songId, count) in group {
                if let count = count {
                    generationCounts[songId] = count
                }
            }
        }
        
        await MainActor.run {
            self.songTags.merge(tags) { _, new in new }
            self.songGenerationCounts.merge(generationCounts) { _, new in new }
        }
        
        return finalSongs
    }
    
    // MARK: - Fallback Methods
    
    private func generatePersonalizedSuggestionsFallback() async throws -> [Song] {
        guard let userProfile = onboardingService.userProfile else {
            return []
        }

        let studyLanguages = userProfile.studyLanguages.map { $0.language.rawValue }
        guard !studyLanguages.isEmpty else {
            return []
        }
        
        guard appleMusicService.isAuthorized else {
            return []
        }
        
        return try await searchSongsByLanguages(studyLanguages)
    }
    
    private func generateDictionaryWordSuggestionsFallback() async throws -> [Song] {
        guard let userProfile = onboardingService.userProfile else {
            return []
        }

        let targetLanguages = Set(userProfile.studyLanguages.map { $0.language.rawValue })
        guard !targetLanguages.isEmpty else {
            return []
        }
        
        guard appleMusicService.isAuthorized else {
            return []
        }
        
        let allWords = wordsProvider.words
        let filteredWords = allWords.filter { word in
            guard let languageCode = word.languageCode,
                  let wordText = word.wordItself else {
                return false
            }
            return targetLanguages.contains(languageCode) && !wordText.isEmpty
        }
        
        guard !filteredWords.isEmpty else {
            return []
        }
        
        var allSuggestions: [Song] = []
        
        for language in targetLanguages {
            let wordsForLanguage = filteredWords.filter { $0.languageCode == language }
            let wordsToSearch = Array(wordsForLanguage.prefix(10))
            
            for word in wordsToSearch {
                guard let wordText = word.wordItself, !wordText.isEmpty else { continue }
                
                do {
                    let songs = try await appleMusicService.searchSongs(
                        query: wordText,
                        language: language
                    )
                    allSuggestions.append(contentsOf: songs)
                } catch {
                    continue
                }
            }
        }
        
        var uniqueSuggestions: [Song] = []
        var seenIds = Set<String>()
        
        for song in allSuggestions {
            if !seenIds.contains(song.id) {
                uniqueSuggestions.append(song)
                seenIds.insert(song.id)
            }
        }
        
        return Array(uniqueSuggestions.prefix(20))
    }
    
    // MARK: - Helper Methods
    
    private func searchSongsByLanguages(_ languages: [String]) async throws -> [Song] {
        var allSuggestions: [Song] = []
        
        for language in languages {
            do {
                // Search for popular songs in the target language
                let songs = try await appleMusicService.searchSongs(
                    query: language,
                    language: language
                )
                allSuggestions.append(contentsOf: songs)
            } catch {
                continue
            }
        }
        
        // Remove duplicates
        var uniqueSuggestions: [Song] = []
        var seenIds = Set<String>()
        
        for song in allSuggestions {
            if !seenIds.contains(song.id) {
                uniqueSuggestions.append(song)
                seenIds.insert(song.id)
            }
        }
        
        return Array(uniqueSuggestions.prefix(20))
    }
    
    // MARK: - Caching
    
    private struct CachedSuggestions: Codable {
        let suggestedSongs: [Song]
        let dictionaryWordSongs: [Song]
    }
    
    private func getCachedSuggestions() -> CachedSuggestions? {
        guard let data = UDService.musicSuggestionsCacheData else { return nil }
        
        do {
            let cached = try JSONDecoder().decode(CachedSuggestions.self, from: data)
            return cached
        } catch {
            print("⚠️ [MusicDiscoveringViewModel] Failed to decode cached suggestions: \(error)")
            return nil
        }
    }
    
    private func saveToCache(suggestedSongs: [Song], dictionaryWordSongs: [Song]) {
        let cached = CachedSuggestions(
            suggestedSongs: suggestedSongs,
            dictionaryWordSongs: dictionaryWordSongs
        )
        
        do {
            let data = try JSONEncoder().encode(cached)
            UDService.musicSuggestionsCacheData = data
            UDService.musicSuggestionsCacheTimestamp = Date()
            print("💾 [MusicDiscoveringViewModel] Suggestions cached successfully")
        } catch {
            print("❌ [MusicDiscoveringViewModel] Failed to cache suggestions: \(error)")
        }
    }
    
    private func isCacheExpired() -> Bool {
        guard let timestamp = UDService.musicSuggestionsCacheTimestamp else { return true }
        let age = Date().timeIntervalSince(timestamp)
        return age > cacheDuration
    }
    
    func clearCache() {
        UDService.musicSuggestionsCacheData = nil
        UDService.musicSuggestionsCacheTimestamp = nil
        print("🗑️ [MusicDiscoveringViewModel] Cache cleared")
    }
}


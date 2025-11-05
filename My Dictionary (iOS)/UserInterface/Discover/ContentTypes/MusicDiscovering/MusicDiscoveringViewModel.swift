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
    @Published private(set) var recommendationItems: [RecommendationItem] = []
    @Published private(set) var recommendationSongs: [Song] = [] // Actual songs with artwork for "Your Daily 5"
    @Published private(set) var masteredSongs: [Song] = []
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
    private let recommendationService = MusicRecommendationService.shared
    private let recommendationFetcher = MusicRecommendationFetcher.shared
    
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
        
        loadingStatus = .loadingSuggestions

        Task {
            do {
                async let recommendations = generateRecommendations()
                async let mastered = generateMasteredSuggestions()
                
                let (recommendationItems, masteredSongs) = try await (recommendations, mastered)
                
                await MainActor.run {
                    self.recommendationItems = recommendationItems
                    self.masteredSongs = masteredSongs
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

    func loadHistory() {
        Task {
            let history = await historyService.getHistory()
            await MainActor.run {
                self.listeningHistory = history
            }
        }
    }

    // MARK: - Song Selection & Playback

    /// Handle selection of recommendation item (artist, album, or song)
    func selectRecommendationItem(_ item: RecommendationItem) async {
        switch item {
        case .artist(let artist):
            // Fetch random song from artist
            do {
                if let song = try await recommendationFetcher.fetchRandomSong(for: artist) {
                    await selectSong(song)
                } else {
                    await MainActor.run {
                        errorReceived(MusicError.songNotFound)
                    }
                }
            } catch {
                await MainActor.run {
                    errorReceived(error)
                }
            }
            
        case .album(let album):
            // Fetch random song from album
            do {
                if let song = try await recommendationFetcher.fetchRandomSong(for: album) {
                    await selectSong(song)
                } else {
                    await MainActor.run {
                        errorReceived(MusicError.songNotFound)
                    }
                }
            } catch {
                await MainActor.run {
                    errorReceived(error)
                }
            }
            
        case .song(let recommendationSong):
            // Search for the actual song by title and artist
            do {
                let query = "\(recommendationSong.title) \(recommendationSong.artist)"
                let songs = try await appleMusicService.searchSongs(query: query, language: nil)
                
                if let song = songs.first(where: {
                    $0.title.lowercased().contains(recommendationSong.title.lowercased()) &&
                    $0.artist.lowercased().contains(recommendationSong.artist.lowercased())
                }) {
                    await selectSong(song)
                } else if let firstMatch = songs.first {
                    await selectSong(firstMatch)
                } else {
                    await MainActor.run {
                        errorReceived(MusicError.songNotFound)
                    }
                }
            } catch {
                await MainActor.run {
                    errorReceived(error)
                }
            }
        }
    }

    func selectSong(_ song: Song) async {
        // Stop current playback
        musicPlayerService.stop()

        currentSong = song

        // Set the queue to mastered songs for navigation (if available)
        // Build queue from mastered songs
        var queueSongs = masteredSongs
        
        // Try to find the selected song in the queue
        if let songIndex = queueSongs.firstIndex(where: { $0.id == song.id }) {
            await MainActor.run {
                musicPlayerService.setQueue(queueSongs, currentIndex: songIndex)
            }
        } else {
            // If song not in queue, add it at the beginning and create queue
            queueSongs.insert(song, at: 0)
            await MainActor.run {
                musicPlayerService.setQueue(queueSongs, currentIndex: 0)
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
        if let session = currentSession, session.song.id != song.id {
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

    // MARK: - Recommendations Generation
    
    /// Generate recommendations with Firestore → OpenAI → Search priority
    private func generateRecommendations() async throws -> [RecommendationItem] {
        guard let userProfile = onboardingService.userProfile,
              let firstStudyLanguage = userProfile.studyLanguages.first else {
            print("⚠️ [MusicDiscoveringViewModel] No user profile or study language")
            return []
        }
        
        let language = firstStudyLanguage.language
        let cefrLevel = firstStudyLanguage.proficiencyLevel.rawValue
        
        print("🔍 [MusicDiscoveringViewModel] Generating recommendations for \(language.englishName)/\(cefrLevel)")

        // 1. Try Firestore cache first
        print("📥 [MusicDiscoveringViewModel] Checking Firestore cache...")
        do {
            if let cachedRecommendations = try await recommendationService.getRecommendations(
                language: language,
                cefrLevel: cefrLevel
            ) {
                print("✅ [MusicDiscoveringViewModel] Found recommendations in Firestore cache")
                return await convertFirestoreRecommendationToItems(cachedRecommendations)
            } else {
                print("ℹ️ [MusicDiscoveringViewModel] No recommendations found in Firestore cache")
            }
        } catch {
            print("⚠️ [MusicDiscoveringViewModel] Error checking Firestore: \(error.localizedDescription)")
            // Continue to OpenAI fallback
        }
        
        // 2. Try OpenAI generation
        print("🤖 [MusicDiscoveringViewModel] Requesting recommendations from OpenAI...")
        print("🤖 [MusicDiscoveringViewModel] Checking if AI request is allowed...")
        print("🤖 [MusicDiscoveringViewModel] AI can make request: \(aiService.canMakeAIRequest())")
        
        do {
            let aiRecommendations = try await recommendationService.generateRecommendationsWithAI(
                language: language,
                cefrLevel: cefrLevel,
                userProfile: userProfile
            )
            print("✅ [MusicDiscoveringViewModel] Successfully received recommendations from OpenAI")
            // AI service automatically saves to Firestore (with songs only), so next user will get it from cache
            return await convertFirestoreRecommendationToItems(aiRecommendations)
        } catch let error as AIError {
            print("❌ [MusicDiscoveringViewModel] OpenAI generation failed with AIError: \(error)")
            print("❌ [MusicDiscoveringViewModel] Error details: \(error.localizedDescription)")
            // 3. Fallback to search
            print("🔍 [MusicDiscoveringViewModel] Falling back to search-based recommendations...")
            do {
                let searchRecommendations = try await recommendationService.generateRecommendationsWithSearch(
                    language: language,
                    cefrLevel: cefrLevel
                )
                print("✅ [MusicDiscoveringViewModel] Generated search-based recommendations")
                // Search service saves to Firestore as well
                return await convertFirestoreRecommendationToItems(searchRecommendations)
            } catch {
                print("❌ [MusicDiscoveringViewModel] All recommendation methods failed: \(error.localizedDescription)")
                throw error
            }
        } catch {
            print("❌ [MusicDiscoveringViewModel] OpenAI generation failed with error: \(error)")
            print("❌ [MusicDiscoveringViewModel] Error type: \(type(of: error))")
            print("❌ [MusicDiscoveringViewModel] Error description: \(error.localizedDescription)")
            // 3. Fallback to search
            print("🔍 [MusicDiscoveringViewModel] Falling back to search-based recommendations...")
            do {
                let searchRecommendations = try await recommendationService.generateRecommendationsWithSearch(
                    language: language,
                    cefrLevel: cefrLevel
                )
                print("✅ [MusicDiscoveringViewModel] Generated search-based recommendations")
                // Search service saves to Firestore as well
                return await convertFirestoreRecommendationToItems(searchRecommendations)
            } catch {
                print("❌ [MusicDiscoveringViewModel] All recommendation methods failed: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    /// Convert FirestoreRecommendation to RecommendationItem array and fetch actual songs with artwork
    /// "Your Daily 5" should only show songs with artwork
    private func convertFirestoreRecommendationToItems(_ recommendation: FirestoreRecommendation) async -> [RecommendationItem] {
        // Search Apple Music for each song recommendation to get actual Song objects with artwork
        var songsWithArtwork: [Song] = []
        
        for songRec in recommendation.songs {
            do {
                let query = "\(songRec.title) \(songRec.artist)"
                let songs = try await appleMusicService.searchSongs(query: query, language: nil)
                
                if let foundSong = songs.first(where: {
                    $0.title.lowercased().contains(songRec.title.lowercased()) &&
                    $0.artist.lowercased().contains(songRec.artist.lowercased())
                }) ?? songs.first {
                    songsWithArtwork.append(foundSong)
                }
            } catch {
                print("⚠️ [MusicDiscoveringViewModel] Failed to find song \(songRec.title): \(error)")
                continue
            }
        }
        
        // Store the actual songs with artwork
        await MainActor.run {
            self.recommendationSongs = songsWithArtwork
        }
        
        // Convert to RecommendationItem array (only songs)
        return recommendation.songs.map { .song($0) }
    }
    
    /// Check if user has mastered any songs
    func hasMasteredSongs() -> Bool {
        let context = CoreDataService.shared.context
        
        return context.performAndWait {
            let fetchRequest = CDMusicQuizPerformance.fetchRequest()
            
            // Get all quiz performances
            guard let performances = try? context.fetch(fetchRequest) else {
                return false
            }
            
            // Check if user has any high-scoring performances (mastered)
            // A song is considered mastered if user got most questions correct
            let songPerformances: [String: [CDMusicQuizPerformance]] = Dictionary(grouping: performances) { $0.songId ?? "" }
            
            for (songId, performances) in songPerformances where !songId.isEmpty {
                let correctCount = performances.filter { $0.isCorrect }.count
                let totalCount = performances.count
                
                // Consider mastered if 80% or more correct
                if totalCount >= 3 && Double(correctCount) / Double(totalCount) >= 0.8 {
                    return true
                }
            }
            
            return false
        }
    }
    
    /// Generate suggestions based on mastered songs
    private func generateMasteredSuggestions() async throws -> [Song] {
        // Only generate if user has mastered songs
        guard hasMasteredSongs() else {
            return []
        }
        
        guard let userProfile = onboardingService.userProfile else {
            return []
        }
        
        // Check if AI service is available
        guard aiService.canMakeAIRequest() else {
            return []
        }
        
        // Check if Apple Music is authenticated
        guard appleMusicService.isAuthorized else {
            return []
        }
        
        // Get user's mastered songs from CoreData
        let context = CoreDataService.shared.context
        let masteredSongIds = context.performAndWait {
            let fetchRequest = CDMusicQuizPerformance.fetchRequest()
            guard let performances = try? context.fetch(fetchRequest) else {
                return Set<String>()
            }
            
            // Group by song and check mastery
            let songPerformances: [String: [CDMusicQuizPerformance]] = Dictionary(grouping: performances) { $0.songId ?? "" }
            var masteredIds = Set<String>()
            
            for (songId, performances) in songPerformances where !songId.isEmpty {
                let correctCount = performances.filter { $0.isCorrect }.count
                let totalCount = performances.count
                
                if totalCount >= 3 && Double(correctCount) / Double(totalCount) >= 0.8 {
                    masteredIds.insert(songId)
                }
            }
            
            return masteredIds
        }
        
        guard !masteredSongIds.isEmpty else {
            return []
        }
        
        // Get user's dictionary words
        let allWords = wordsProvider.words
        let targetLanguages = Set(userProfile.studyLanguages.map { $0.language.rawValue })
        let filteredWords = allWords.filter { word in
            guard let languageCode = word.languageCode else { return false }
            return targetLanguages.contains(languageCode)
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
        
        // Request AI suggestions based on mastered songs and dictionary words
        let aiResponse: AISongSuggestionsResponse = try await aiService.request(
            .musicSuggestions(
                userProfile: userProfile,
                dictionaryWords: dictionaryWords.isEmpty ? nil : dictionaryWords
            )
        )
        
        // Search Apple Music for AI-suggested songs
        var foundSongs: [Song] = []
        
        for suggestion in aiResponse.dictionaryWordSongs {
            do {
                let query = "\(suggestion.title) \(suggestion.artist)"
                let songs = try await appleMusicService.searchSongs(
                    query: query,
                    language: suggestion.language
                )
                
                if let exactMatch = songs.first(where: {
                    $0.title.lowercased().contains(suggestion.title.lowercased()) &&
                    $0.artist.lowercased().contains(suggestion.artist.lowercased())
                }) {
                    foundSongs.append(exactMatch)
                } else if let firstMatch = songs.first {
                    foundSongs.append(firstMatch)
                }
            } catch {
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
        
        // Load song tags and generation counts
        let songIds = finalSongs.map { $0.id }
        let tags = await songTagService.getTags(for: songIds)
        
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

    // MARK: - Legacy Methods (kept for compatibility during transition)

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


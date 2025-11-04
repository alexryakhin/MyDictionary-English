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
    @Published private(set) var listeningHistory: [MusicListeningHistory] = []
    @Published private(set) var currentSession: MusicDiscoveringSession?
    @Published private(set) var currentSong: Song?
    @Published private(set) var currentLyrics: SongLyrics?
    @Published private(set) var aiContent: MusicDiscoveringResponse?

    // AI loading states
    @Published var isLoadingExplanation = false
    @Published var isLoadingQuiz = false
    @Published var isLoadingVocabulary = false

    private let appleMusicService = AppleMusicService.shared
    private let musicPlayerService = MusicPlayerService.shared
    private let lyricsService = LRCLibService.shared
    private let aiService = AIService.shared
    private let onboardingService = OnboardingService.shared
    private let historyService = MusicListeningHistoryService.shared

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
                let songs = try await generatePersonalizedSuggestions()
                await MainActor.run {
                    self.suggestedSongs = songs
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

    func selectSong(_ song: Song) async {
        // Stop current playback
        musicPlayerService.stop()

        currentSong = song

        // Set the queue to suggested songs for navigation
        if let songIndex = suggestedSongs.firstIndex(where: { $0.id == song.id }) {
            await MainActor.run {
                musicPlayerService.setQueue(suggestedSongs, currentIndex: songIndex)
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
            let targetLanguage = firstStudyLanguage.language

            let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics ?? ""
            guard !lyricsText.isEmpty else {
                throw AIError.invalidResponse
            }
            let response: MusicDiscoveringResponse = try await aiService.request(.musicContent(
                song: song,
                lyrics: lyrics,
                targetLanguage: targetLanguage,
                cefrLevel: cefrLevel
            ))

            await MainActor.run {
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

            let targetLanguage = firstStudyLanguage.language

            let lyricsText = lyrics.bestLyrics ?? lyrics.plainLyrics ?? ""
            guard !lyricsText.isEmpty else {
                throw AIError.invalidResponse
            }
            let quiz: AIComprehensionQuiz = try await aiService.request(.musicQuiz(
                song: song,
                lyrics: lyrics,
                targetLanguage: targetLanguage
            ))

            await MainActor.run {
                // Update AI content with quiz
                if var content = self.aiContent {
                    // Create new response with quiz
                    // For now, we'll store quiz separately or update existing content
                }
                self.isLoadingQuiz = false
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

        // Get study languages
        let studyLanguages = userProfile.studyLanguages.map { $0.language.rawValue }
        guard let targetLanguage = studyLanguages.first else {
            return []
        }

        // Get user interests for search terms
        let interests = userProfile.interests.map { $0.rawValue }
        
        // Check if Apple Music is authenticated
        guard appleMusicService.isAuthorized else {
            return []
        }
        
        var allSuggestions: [Song] = []
        
        // Search songs based on interests and target language
        // Combine interests with language for search
        let searchTerms = interests.prefix(3) // Use top 3 interests
        for interest in searchTerms {
            do {
                let songs = try await appleMusicService.searchSongs(
                    query: "\(interest) \(targetLanguage)",
                    language: targetLanguage
                )
                allSuggestions.append(contentsOf: songs)
            } catch {
                // Continue with other interests
                continue
            }
        }

        // Remove duplicates and prioritize songs with available lyrics
        var uniqueSuggestions: [Song] = []
        var seenIds = Set<String>()

        for song in allSuggestions {
            if !seenIds.contains(song.id) {
                uniqueSuggestions.append(song)
                seenIds.insert(song.id)
            }
        }

        // Limit to top 20 suggestions
        return Array(uniqueSuggestions.prefix(20))
    }
}


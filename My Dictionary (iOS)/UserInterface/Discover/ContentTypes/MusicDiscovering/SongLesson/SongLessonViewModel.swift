//
//  SongLessonViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SongLessonViewModel: BaseViewModel {
    
    enum Input {
        case loadLesson(Song)
        case submitQuizAnswer(questionIndex: Int, answerIndex: Int, isCorrect: Bool)
        case markQuizComplete
        case addDiscoveredWord(String)
        case markExplanationRequested
        case updateSession(MusicDiscoveringSession)
        case saveSession
        case navigateToResults
    }
    
    enum LessonLoadingState: Equatable {
        case idle
        case loading
        case loaded(AdaptedLesson)
        case error(String)
    }
    
    @Published private(set) var loadingState: LessonLoadingState = .idle
    @Published private(set) var currentSession: MusicDiscoveringSession?
    @Published private(set) var lesson: AdaptedLesson?
    @Published var shouldNavigateToResults: Bool = false
    
    private let musicLessonService = MusicLessonService.shared
    private let songLessonSessionService = SongLessonSessionService.shared
    private let lyricsService = LRCLibService.shared

    // MARK: - Input Handler
    
    func handle(_ input: Input) {
        switch input {
        case .loadLesson(let song):
            Task {
                await loadLesson(for: song)
            }
        case .submitQuizAnswer(let questionIndex, let answerIndex, let isCorrect):
            submitQuizAnswer(questionIndex: questionIndex, answerIndex: answerIndex, isCorrect: isCorrect)
        case .markQuizComplete:
            markQuizComplete()
        case .addDiscoveredWord(let word):
            addDiscoveredWord(word)
        case .markExplanationRequested:
            markExplanationRequested()
        case .updateSession(let session):
            updateSession(session)
        case .saveSession:
            saveSession()
        case .navigateToResults:
            navigateToResults()
        }
    }
    
    @discardableResult
    func handleAsync(_ input: Input) -> Task<Void, Never>? {
        switch input {
        case .loadLesson:
            handle(input)
            return nil
        default:
            handle(input)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func loadLesson(for song: Song) async {
        loadingState = .loading
        
        do {
            // Check if we have an existing session
            if let existingSession = songLessonSessionService.getSession(by: song.id),
               let lesson = existingSession.lesson,
               let session = existingSession.session {
                // Use existing lesson and session
                self.lesson = lesson
                self.currentSession = session
                loadingState = .loaded(lesson)
            } else {
                // Get lyrics first
                let lyrics = try await lyricsService.getLyrics(
                    trackName: song.title,
                    artistName: song.artist,
                    albumName: song.album,
                    duration: song.duration
                )
                
                // Generate new lesson
                let adaptedLesson = try await musicLessonService.getLesson(for: song, lyrics: lyrics)
                self.lesson = adaptedLesson
                
                // Create new session
                let session = MusicDiscoveringSession(song: song)
                self.currentSession = session
                
                // Save to CoreData
                try await songLessonSessionService.saveOrUpdateSession(
                    session,
                    lesson: adaptedLesson,
                    song: song
                )
                
                loadingState = .loaded(adaptedLesson)
            }
        } catch {
            logError("Failed to load lesson: \(error.localizedDescription)")
            loadingState = .error(error.localizedDescription)
        }
    }
    
    private func submitQuizAnswer(questionIndex: Int, answerIndex: Int, isCorrect: Bool) {
        guard var session = currentSession else { return }
        session.submitQuizAnswer(questionIndex: questionIndex, answerIndex: answerIndex, isCorrect: isCorrect)
        currentSession = session
        saveSession()
    }
    
    private func markQuizComplete() {
        guard var session = currentSession else { return }
        session.markQuizComplete()
        currentSession = session
        saveSession()
    }
    
    private func addDiscoveredWord(_ word: String) {
        guard var session = currentSession else { return }
        session.addDiscoveredWord(word)
        currentSession = session
        saveSession()
    }
    
    private func markExplanationRequested() {
        guard var session = currentSession else { return }
        session.markExplanationRequested()
        currentSession = session
        saveSession()
    }
    
    private func updateSession(_ session: MusicDiscoveringSession) {
        currentSession = session
        saveSession()
    }
    
    private func saveSession() {
        guard let session = currentSession,
              let lesson = lesson else { return }
        
        Task {
            do {
                try await songLessonSessionService.saveOrUpdateSession(
                    session,
                    lesson: lesson,
                    song: session.song
                )
            } catch {
                logError("Failed to save session: \(error.localizedDescription)")
            }
        }
    }
    
    private func navigateToResults() {
        shouldNavigateToResults = true
    }
}


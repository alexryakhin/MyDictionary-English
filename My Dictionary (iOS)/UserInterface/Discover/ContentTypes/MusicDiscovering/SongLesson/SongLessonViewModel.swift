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
        case submitQuizAnswer(questionIndex: Int, answerIndex: Int, isCorrect: Bool)
        case markQuizComplete
        case addDiscoveredWord(String)
        case markExplanationRequested
        case updateSession(MusicDiscoveringSession)
        case saveSession
        case navigateToResults
    }
    
    @Published private(set) var currentSession: MusicDiscoveringSession
    @Published private(set) var lesson: AdaptedLesson
    @Published var shouldNavigateToResults: Bool = false
    
    private let songLessonSessionService = SongLessonSessionService.shared
    private let song: Song

    init(song: Song, lesson: AdaptedLesson, session: MusicDiscoveringSession) {
        self.song = song
        self.lesson = lesson
        self.currentSession = session
        super.init()
        
        Task {
            do {
                try await songLessonSessionService.saveOrUpdateSession(
                    session,
                    lesson: lesson,
                    song: song
                )
            } catch {
                logError("Failed to persist initial session: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Input Handler
    
    func handle(_ input: Input) {
        switch input {
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
        default:
            handle(input)
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func submitQuizAnswer(questionIndex: Int, answerIndex: Int, isCorrect: Bool) {
        var session = currentSession
        session.submitQuizAnswer(questionIndex: questionIndex, answerIndex: answerIndex, isCorrect: isCorrect)
        currentSession = session
        saveSession()
    }
    
    private func markQuizComplete() {
        var session = currentSession
        session.markQuizComplete()
        currentSession = session
        saveSession()
    }
    
    private func addDiscoveredWord(_ word: String) {
        var session = currentSession
        session.addDiscoveredWord(word)
        currentSession = session
        saveSession()
    }
    
    private func markExplanationRequested() {
        var session = currentSession
        session.markExplanationRequested()
        currentSession = session
        saveSession()
    }
    
    private func updateSession(_ session: MusicDiscoveringSession) {
        currentSession = session
        saveSession()
    }
    
    private func saveSession() {
        Task {
            do {
                try await songLessonSessionService.saveOrUpdateSession(
                    currentSession,
                    lesson: lesson,
                    song: song
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


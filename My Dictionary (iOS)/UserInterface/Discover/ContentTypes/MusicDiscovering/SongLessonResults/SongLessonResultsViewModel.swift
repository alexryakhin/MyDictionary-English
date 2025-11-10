//
//  SongLessonResultsViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SongLessonResultsViewModel: BaseViewModel {
    
    enum Input {
        case loadResults(MusicDiscoveringSession)
        case toggleFavorite
    }
    
    @Published private(set) var session: MusicDiscoveringSession?
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var resolvedListeningTime: TimeInterval = 0
    
    private let songLessonSessionService = SongLessonSessionService.shared
    private let historyService = MusicListeningHistoryService.shared
    
    // MARK: - Computed Properties
    
    var accuracy: Int {
        session?.quizScore ?? 0
    }
    
    var correctAnswers: Int {
        session?.quizAnswers.filter { $0.isCorrect }.count ?? 0
    }
    
    var totalQuestions: Int {
        session?.quizAnswers.count ?? 0
    }
    
    var discoveredWordsCount: Int {
        session?.discoveredWords.count ?? 0
    }
    
    var completionPercentage: Double {
        session?.completionPercentage ?? 0
    }
    
    var listeningTime: TimeInterval {
        max(session?.totalListeningTime ?? 0, resolvedListeningTime)
    }
    
    var formattedListeningTime: String {
        let minutes = Int(listeningTime) / 60
        let seconds = Int(listeningTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Input Handler
    
    func handle(_ input: Input) {
        switch input {
        case .loadResults(let session):
            Task {
                await loadResults(session)
            }
        case .toggleFavorite:
            toggleFavorite()
        }
    }
    
    @discardableResult
    func handleAsync(_ input: Input) -> Task<Void, Never>? {
        handle(input)
        return nil
    }
    
    // MARK: - Private Methods
    
    private func loadResults(_ session: MusicDiscoveringSession) async {
        var resolvedSession = session
        let storedSession = songLessonSessionService.getSession(by: session.song.id)
        
        if let stored = storedSession?.toMusicDiscoveringSession() {
            resolvedSession = stored
        }
        
        // Derive listening time from multiple sources
        var derivedListeningTime = max(resolvedSession.totalListeningTime, session.totalListeningTime)
        
        if let latestAnswerDate = resolvedSession.quizAnswers.max(by: { $0.answeredAt < $1.answeredAt })?.answeredAt {
            let elapsed = latestAnswerDate.timeIntervalSince(resolvedSession.startedAt)
            if elapsed.isFinite && elapsed > 0 {
                derivedListeningTime = max(derivedListeningTime, elapsed)
            }
        }
        
        if let history = await historyService.getHistoryForSong(session.song.id) {
            derivedListeningTime = max(derivedListeningTime, history.listeningDuration)
        }
        
        resolvedSession.totalListeningTime = max(resolvedSession.totalListeningTime, derivedListeningTime)
        self.session = resolvedSession
        self.resolvedListeningTime = resolvedSession.totalListeningTime
        self.isFavorite = storedSession?.isFavorite ?? isFavorite
    }
    
    private func toggleFavorite() {
        guard let session = session else { return }
        
        do {
            try songLessonSessionService.toggleFavorite(song: session.song)
            isFavorite.toggle()
        } catch {
            errorReceived(error)
        }
    }

}

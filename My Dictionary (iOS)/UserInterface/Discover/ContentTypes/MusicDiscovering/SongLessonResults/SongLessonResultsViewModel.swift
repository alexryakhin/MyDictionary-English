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
        case shareResults
        case toggleFavorite
    }
    
    @Published private(set) var session: MusicDiscoveringSession?
    @Published private(set) var isFavorite: Bool = false
    @Published var showShareSheet: Bool = false
    
    private let songLessonSessionService = SongLessonSessionService.shared
    
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
        session?.totalListeningTime ?? 0
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
            loadResults(session)
        case .shareResults:
            shareResults()
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
    
    private func loadResults(_ session: MusicDiscoveringSession) {
        self.session = session
        
        // Check if song is in favorites
        if let cdSession = songLessonSessionService.getSession(by: session.song.id) {
            isFavorite = cdSession.isFavorite
        }
    }
    
    private func shareResults() {
        showShareSheet = true
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

    var shareText: String {
        guard let session = session else { return "" }
        return """
        🎵 I just completed a music lesson!
        Song: \(session.song.title) by \(session.song.artist)
        Score: \(accuracy)%
        Discovered: \(discoveredWordsCount) new words
        """
    }
}

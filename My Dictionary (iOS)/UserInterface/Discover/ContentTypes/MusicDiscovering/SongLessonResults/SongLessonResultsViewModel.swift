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
    @Published private(set) var showStreakAnimation: Bool = false
    @Published private(set) var currentDayStreak: Int?
    
    private let songLessonSessionService = SongLessonSessionService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let quizAnalyticsService = QuizAnalyticsService.shared
    
    private var storedSessionId: UUID?
    private var recordedQuizSessionId: UUID?
    
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
        showStreakAnimation = false
        currentDayStreak = nil
        
        var resolvedSession = session
        let storedSession = songLessonSessionService.getSession(by: session.song.id)
        
        if let stored = storedSession?.toMusicDiscoveringSession() {
            resolvedSession = stored
        }
        storedSessionId = storedSession?.id
        recordedQuizSessionId = storedSession?.quizSessionId
        
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
        
        recordAnalyticsIfNeeded(for: resolvedSession)
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

    func setStreakAnimationActive(_ isActive: Bool) {
        showStreakAnimation = isActive
    }

    private func recordAnalyticsIfNeeded(for session: MusicDiscoveringSession) {
        guard session.hasCompletedQuiz,
              session.quizAnswers.isNotEmpty else { return }
        if recordedQuizSessionId != nil {
            return
        }
        
        let correctAnswers = session.quizAnswers.filter { $0.isCorrect }.count
        let totalQuestions = session.quizAnswers.count
        let accuracyValue = Double(correctAnswers) / Double(totalQuestions)
        let score = (correctAnswers * 5) - ((totalQuestions - correctAnswers) * 2)
        let duration = listeningTime
        
        let wasFirstQuizToday = quizAnalyticsService.isFirstQuizToday()
        
        let quizSessionId = quizAnalyticsService.saveQuizSession(
            quizType: Quiz.musicLesson.rawValue,
            score: score,
            correctAnswers: correctAnswers,
            totalItems: totalQuestions,
            duration: duration,
            accuracy: accuracyValue,
            itemsPracticed: [],
            correctItemIds: []
        )
        
        if wasFirstQuizToday {
            let newStreak = quizAnalyticsService.calculateCurrentStreak()
            currentDayStreak = newStreak
            showStreakAnimation = true
        }
        
        if let quizSessionId {
            recordedQuizSessionId = quizSessionId
            persistAnalyticsState(quizSessionId: quizSessionId)
        } else {
            logError("[SongLessonResultsViewModel] Failed to obtain quiz session ID after save")
        }
    }

    private func persistAnalyticsState(quizSessionId: UUID?) {
        guard let storedSessionId else {
            logError("[SongLessonResultsViewModel] Missing stored session id when persisting analytics state")
            return
        }
        Task {
            do {
                try await songLessonSessionService.setQuizSessionId(quizSessionId, forSessionId: storedSessionId)
            } catch {
                logError("[SongLessonResultsViewModel] Failed to persist quizSessionId: \(error.localizedDescription)")
            }
        }
    }
}

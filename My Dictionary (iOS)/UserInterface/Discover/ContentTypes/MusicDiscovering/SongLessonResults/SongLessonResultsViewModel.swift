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
    
    @Published private(set) var session: MusicDiscoveringSession
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var resolvedListeningTime: TimeInterval
    @Published private(set) var showStreakAnimation: Bool = false
    @Published private(set) var currentDayStreak: Int?
    
    private let songLessonSessionService = SongLessonSessionService.shared
    private let historyService = MusicListeningHistoryService.shared
    private let quizAnalyticsService = QuizAnalyticsService.shared
    
    private var storedSessionId: UUID?
    private var recordedQuizSessionId: UUID?
    
    init(session: MusicDiscoveringSession) {
        self.session = session
        self.resolvedListeningTime = session.totalListeningTime
        super.init()
        Task {
            await bootstrap()
        }
    }
    
    // MARK: - Computed Properties
    
    var accuracy: Int {
        session.quizScore
    }
    
    var correctAnswers: Int {
        session.quizAnswers.filter { $0.isCorrect }.count
    }
    
    var totalQuestions: Int {
        session.quizAnswers.count
    }
    
    var discoveredWordsCount: Int {
        session.discoveredWords.count
    }
    
    var completionPercentage: Double {
        session.completionPercentage
    }
    
    var listeningTime: TimeInterval {
        max(session.totalListeningTime, resolvedListeningTime)
    }
    
    var formattedListeningTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .short
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: listeningTime) ?? "0s"
    }

    // MARK: - Public API
    
    func toggleFavorite() {
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
    
    // MARK: - Private Helpers
    
    private func bootstrap() async {
        if let stored = songLessonSessionService.getSession(by: session.song.id) {
            storedSessionId = stored.id
            recordedQuizSessionId = stored.quizSessionId
            isFavorite = stored.isFavorite
        } else {
            storedSessionId = session.id
        }
        
        recordAnalyticsIfNeeded()
    }
    
    private func recordAnalyticsIfNeeded() {
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

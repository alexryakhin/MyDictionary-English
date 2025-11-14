//
//  MusicDiscoveringSession.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

struct MusicDiscoveringSession: Codable, Hashable, Identifiable {
    let id: UUID
    let song: Song
    var listeningProgress: TimeInterval
    var totalListeningTime: TimeInterval
    var quizAnswers: [QuizAnswer]
    var discoveredWords: Set<String>
    var hasRequestedExplanation: Bool
    var hasCompletedQuiz: Bool
    let startedAt: Date
    var lastPlayedAt: Date
    
    struct QuizAnswer: Hashable, Codable {
        enum QuizType: String, Codable {
            case fillInBlank
            case meaningMCQ
            case pronunciation
        }
        
        let questionIndex: Int
        let selectedAnswerIndex: Int
        let isCorrect: Bool
        let answeredAt: Date
        let type: QuizType
        let spokenText: String?
        
        init(
            questionIndex: Int,
            selectedAnswerIndex: Int,
            isCorrect: Bool,
            type: QuizType,
            answeredAt: Date = Date(),
            spokenText: String? = nil
        ) {
            self.questionIndex = questionIndex
            self.selectedAnswerIndex = selectedAnswerIndex
            self.isCorrect = isCorrect
            self.answeredAt = answeredAt
            self.type = type
            self.spokenText = spokenText
        }
        
        func matches(questionIndex: Int, type: QuizType) -> Bool {
            self.questionIndex == questionIndex && self.type == type
        }
    }
    
    init(song: Song) {
        self.id = UUID()
        self.song = song
        self.listeningProgress = 0
        self.totalListeningTime = 0
        self.quizAnswers = []
        self.discoveredWords = Set<String>()
        self.hasRequestedExplanation = false
        self.hasCompletedQuiz = false
        self.startedAt = Date()
        self.lastPlayedAt = Date()
    }
    
    init(
        id: UUID,
        song: Song,
        listeningProgress: TimeInterval = 0,
        totalListeningTime: TimeInterval = 0,
        quizAnswers: [QuizAnswer] = [],
        discoveredWords: Set<String> = [],
        hasRequestedExplanation: Bool = false,
        hasCompletedQuiz: Bool = false,
        startedAt: Date = Date(),
        lastPlayedAt: Date = Date()
    ) {
        self.id = id
        self.song = song
        self.listeningProgress = listeningProgress
        self.totalListeningTime = totalListeningTime
        self.quizAnswers = quizAnswers
        self.discoveredWords = discoveredWords
        self.hasRequestedExplanation = hasRequestedExplanation
        self.hasCompletedQuiz = hasCompletedQuiz
        self.startedAt = startedAt
        self.lastPlayedAt = lastPlayedAt
    }
    
    var completionPercentage: Double {
        guard song.duration > 0 else { return 0 }
        return min(listeningProgress / song.duration, 1.0) * 100
    }
    
    var quizScore: Int {
        guard !quizAnswers.isEmpty else { return 0 }
        let correctAnswers = quizAnswers.filter { $0.isCorrect }.count
        return Int((Double(correctAnswers) / Double(quizAnswers.count)) * 100)
    }
    
    mutating func updateProgress(_ progress: TimeInterval) {
        listeningProgress = progress
        lastPlayedAt = Date()
    }
    
    mutating func addListeningTime(_ time: TimeInterval) {
        totalListeningTime += time
        lastPlayedAt = Date()
    }
    
    mutating func submitQuizAnswer(_ submission: SongLesson.QuizSubmission) {
        let quizType = submission.type.sessionQuizType
        let answer = QuizAnswer(
            questionIndex: submission.questionIndex,
            selectedAnswerIndex: submission.selectedAnswerIndex,
            isCorrect: submission.isCorrect,
            type: quizType,
            answeredAt: Date(),
            spokenText: submission.spokenText
        )
        quizAnswers.removeAll { $0.matches(questionIndex: answer.questionIndex, type: quizType) }
        quizAnswers.append(answer)
    }
    
    mutating func markQuizComplete() {
        hasCompletedQuiz = true
    }
    
    mutating func addDiscoveredWord(_ word: String) {
        discoveredWords.insert(word.lowercased())
    }
    
    mutating func markExplanationRequested() {
        hasRequestedExplanation = true
    }
}


//
//  SpellingQuizViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import Foundation
import Combine

final class SpellingQuizViewModel: BaseViewModel {

    enum Input {
        case confirmAnswer
        case skipWord
        case nextWord
        case restartQuiz
        case dismiss
    }

    @Published var answerTextField = ""

    @Published private(set) var words: [CDWord] = []
    @Published private(set) var randomWord: CDWord?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var attemptCount = 0
    @Published private(set) var isShowingCorrectAnswer = false
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [CDWord] = []
    @Published private(set) var correctWordIds: [String] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var isShowingHint = false
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0

    private let wordsProvider: WordsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalWords: [CDWord] = []
    private var sessionStartTime: Date = Date()
    private let wordCount: Int

    init(wordCount: Int = 10) {
        self.wordCount = wordCount
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .confirmAnswer:
            confirmAnswer()
        case .skipWord:
            skipWord()
        case .nextWord:
            proceedToNextWord()
        case .restartQuiz:
            restartQuiz()
        case .dismiss:
            dismissPublisher.send()
        }
    }

    private func confirmAnswer() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.id == randomWord.id })
        else { return }

        if answerTextField.lowercased().trimmed == (randomWord.wordItself?.lowercased().trimmed ?? "") {
            // Correct answer - show success message
            isCorrectAnswer = true
            isShowingCorrectAnswer = true
            attemptCount = 0
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            wordsPlayed.append(randomWord)
            correctWordIds.append(randomWord.id?.uuidString ?? "")
            isShowingHint = false // Reset hint for next question
            
            // Update score (bonus for fewer attempts)
            let attemptBonus = max(0, 3 - attemptCount) * 10
            score += 100 + attemptBonus
            
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        } else {
            // Incorrect answer
            isCorrectAnswer = false
            attemptCount += 1
            currentStreak = 0 // Reset streak on wrong answer
            
            // Show hint after 2 attempts
            if attemptCount >= 2 {
                isShowingHint = true
            }
            
            // After 3 attempts, mark word as needs review
            if attemptCount >= 3 {
                updateWordDifficultyLevel(word: randomWord, level: 2)
            }
            
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        }
    }
    
    private func proceedToNextWord() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.id == randomWord.id })
        else { return }
        
        // Clear the answer field and remove the current word
        answerTextField = ""
        words.remove(at: wordIndex)
        isShowingCorrectAnswer = false
        
        // Move to next word or complete quiz
        if !words.isEmpty {
            self.randomWord = words.randomElement()
        } else {
            self.randomWord = nil
            isQuizComplete = true
            saveQuizSession()
        }
    }

    private func skipWord() {
        guard let randomWord else { return }
        
        // Mark skipped word as needs review
        updateWordDifficultyLevel(word: randomWord, level: 2)
        
        // Remove word from list (don't move to end)
        if let wordIndex = words.firstIndex(where: { $0.id == randomWord.id }) {
            words.remove(at: wordIndex)
        }
        
        // Penalty for skipping
        score = max(0, score - 25)
        currentStreak = 0
        answerTextField = ""
        
        // Check if quiz is complete
        if words.isEmpty {
            self.randomWord = nil
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next word
            self.randomWord = words.randomElement()
            attemptCount = 0
            isCorrectAnswer = true
            isShowingHint = false
        }
        
        AnalyticsService.shared.logEvent(.spellingQuizWordSkipped)
    }
    
    private func updateWordDifficultyLevel(word: CDWord, level: Int32) {
        word.difficultyLevel = level
        word.isSynced = false  // Mark as unsynced to trigger Firebase sync
        word.updatedAt = Date()
        do {
            try CoreDataService.shared.saveContext()
        } catch {
            print("❌ Failed to update word difficulty level: \(error)")
        }
    }
    
    private func restartQuiz() {
        // Reset all game state
        let limitedWords = Array(originalWords.shuffled().prefix(wordCount))
        words = limitedWords
        randomWord = words.randomElement()
        answerTextField = ""
        isCorrectAnswer = true
        attemptCount = 0
        correctAnswers = 0
        totalQuestions = limitedWords.count
        score = 0
        wordsPlayed = []
        correctWordIds = []
        isQuizComplete = false
        isShowingHint = false
        isShowingCorrectAnswer = false
        currentStreak = 0
        sessionStartTime = Date()
        
        AnalyticsService.shared.logEvent(.spellingQuizRestarted)
    }
    
    private func saveQuizSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
        
        quizAnalyticsService.saveQuizSession(
            quizType: "spelling",
            score: score,
            correctAnswers: correctAnswers,
            totalWords: totalQuestions,
            duration: duration,
            accuracy: accuracy,
            wordsPracticed: wordsPlayed,
            correctWordIds: correctWordIds
        )
        
        // Check and schedule notifications after quiz completion
        ServiceManager.shared.notificationService.checkAndScheduleNotifications()
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.originalWords = words
                // Limit words to the selected count
                let limitedWords = Array(words.shuffled().prefix(self?.wordCount ?? 10))
                self?.words = limitedWords
                self?.randomWord = self?.words.randomElement()
                self?.totalQuestions = limitedWords.count
            }
            .store(in: &cancellables)
    }
}

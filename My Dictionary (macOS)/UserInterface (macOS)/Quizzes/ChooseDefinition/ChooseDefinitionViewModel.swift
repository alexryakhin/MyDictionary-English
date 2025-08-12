//
//  ChooseDefinitionViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import Foundation
import Combine

final class ChooseDefinitionViewModel: BaseViewModel {

    enum Input {
        case selectAnswer(Int)
        case playWord
        case skipWord
        case nextWord
        case restartQuiz
        case dismiss
    }

    @Published private(set) var words: [CDWord] = []
    @Published private(set) var currentQuestion: CDWord?
    @Published private(set) var answerOptions: [CDWord] = []
    @Published private(set) var correctAnswerIndex = 0
    @Published private(set) var selectedAnswerIndex: Int?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var isShowingAnswerFeedback = false
    @Published private(set) var answerFeedback = ""
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [CDWord] = []
    @Published private(set) var correctWordIds: [String] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var questionsAnswered = 0

    private let wordsProvider: WordsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private let ttsPlayer: TTSPlayer = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalWords: [CDWord] = []
    private var feedbackTimer: Timer?
    private var sessionStartTime: Date = Date()
    private let wordCount: Int
    private let hardWordsOnly: Bool

    init(
        wordCount: Int,
        hardWordsOnly: Bool
    ) {
        self.wordCount = wordCount
        self.hardWordsOnly = hardWordsOnly
        super.init()
        setupBindings()
        pauseSharedDictionaryListeners()
    }
    
    deinit {
        resumeSharedDictionaryListeners()
    }
    
    private func pauseSharedDictionaryListeners() {
        print("🔇 [macOS ChooseDefinitionViewModel] Pausing shared dictionary listeners during quiz")
        DictionaryService.shared.pauseAllListeners()
    }
    
    private func resumeSharedDictionaryListeners() {
        print("🔊 [macOS ChooseDefinitionViewModel] Resuming shared dictionary listeners after quiz")
        DictionaryService.shared.resumeAllListeners()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectAnswer(let index):
            selectAnswer(index)
        case .playWord:
            playWord()
        case .skipWord:
            skipWord()
        case .nextWord:
            moveToNextQuestion()
        case .restartQuiz:
            restartQuiz()
        case .dismiss:
            dismissPublisher.send()
        }
    }

    private func selectAnswer(_ index: Int) {
        guard let currentQuestion = currentQuestion else { return }
        
        selectedAnswerIndex = index
        let selectedWord = answerOptions[index]
        
        if selectedWord.id == currentQuestion.id {
            // Correct answer
            isCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            wordsPlayed.append(currentQuestion)
            correctWordIds.append(currentQuestion.id?.uuidString ?? "")
            answerFeedback = "Correct! Well done!"
            
            // Update score
            score += 100
            
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        } else {
            // Incorrect answer
            isCorrectAnswer = false
            currentStreak = 0
            answerFeedback = "Incorrect! Moving to next question..."
            
            // Mark word as needs review
            updateWordScore(word: currentQuestion, score: 2)

            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        }
        
        isShowingAnswerFeedback = true
        questionsAnswered += 1
        
        // Auto-progress after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.moveToNextQuestion()
        }
    }
    
    private func moveToNextQuestion() {
        // Remove current question from words
        if let currentQuestion = currentQuestion,
           let index = words.firstIndex(where: { $0.id == currentQuestion.id }) {
            words.remove(at: index)
        }
        
        // Reset state
        selectedAnswerIndex = nil
        isShowingAnswerFeedback = false
        answerFeedback = ""
        
        // Check if quiz is complete
        if words.isEmpty {
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Set up next question
            setupNextQuestion()
        }
    }
    
    private func setupNextQuestion() {
        guard !words.isEmpty else { return }
        
        // Select a random word as the correct answer
        currentQuestion = words.randomElement()
        
        // Create answer options (correct answer + 2 random wrong answers)
        var options = [currentQuestion!]
        
        // Get 2 random wrong answers from remaining words
        let remainingWords = words.filter { $0.id != currentQuestion!.id }
        let wrongAnswers = remainingWords.shuffled().prefix(2)
        options.append(contentsOf: wrongAnswers)
        
        // If we don't have enough wrong answers, use some from the original list
        if options.count < 3 {
            let additionalWords = originalWords.filter { word in
                !options.contains { $0.id == word.id }
            }
            let additionalOptions = additionalWords.shuffled().prefix(3 - options.count)
            options.append(contentsOf: additionalOptions)
        }
        
        // Shuffle the options
        answerOptions = options.shuffled()
        
        // Find the index of the correct answer
        correctAnswerIndex = answerOptions.firstIndex { $0.id == currentQuestion!.id } ?? 0
    }
    
    private func skipWord() {
        guard let currentQuestion = currentQuestion else { return }
        
        // Mark skipped word as needs review
        updateWordScore(word: currentQuestion, score: 2)

        // Remove word from list
        if let index = words.firstIndex(where: { $0.id == currentQuestion.id }) {
            words.remove(at: index)
        }
        
        // Update quiz score - subtract 2 points for skipping
        score -= 2
        currentStreak = 0
        
        // Check if quiz is complete
        if words.isEmpty {
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Set up next question
            setupNextQuestion()
        }
        
        AnalyticsService.shared.logEvent(.definitionQuizWordSkipped)
    }
    
    private func updateWordScore(word: CDWord, score: Int32) {
        word.difficultyScore = score
        word.isSynced = false  // Mark as unsynced to trigger Firebase sync
        word.updatedAt = Date()
        do {
            try CoreDataService.shared.saveContext()
        } catch {
            print("❌ Failed to update word difficulty level: \(error)")
        }
    }
    
    private func playWord() {
        guard let currentQuestion = currentQuestion else { return }
        
        Task {
            if let wordText = currentQuestion.wordItself {
                do {
                    try await ttsPlayer.play(wordText)
                } catch {
                    errorReceived(error, displayType: .alert)
                }
            }
        }
    }
    
    private func restartQuiz() {
        // Reset all game state
        let limitedWords = Array(originalWords.shuffled().prefix(wordCount))
        words = limitedWords
        currentQuestion = nil
        answerOptions = []
        correctAnswerIndex = 0
        selectedAnswerIndex = nil
        isCorrectAnswer = true
        isShowingAnswerFeedback = false
        answerFeedback = ""
        correctAnswers = 0
        totalQuestions = limitedWords.count
        score = 0
        wordsPlayed = []
        correctWordIds = []
        isQuizComplete = false
        currentStreak = 0
        questionsAnswered = 0
        sessionStartTime = Date()
        
        // Set up first question
        setupNextQuestion()
        
        AnalyticsService.shared.logEvent(.definitionQuizRestarted)
    }
    
    private func saveQuizSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0.0
        
        quizAnalyticsService.saveQuizSession(
            quizType: "definition",
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
                self?.totalQuestions = limitedWords.count
                self?.setupNextQuestion()
            }
            .store(in: &cancellables)
    }
}

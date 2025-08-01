import Foundation
import Combine

final class ChooseDefinitionQuizViewModel: BaseViewModel {

    enum Input {
        case answerSelected(Int)
        case skipWord
        case restartQuiz
        case dismiss
    }

    @Published private(set) var words: [CDWord] = []
    @Published private(set) var correctAnswerIndex: Int
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var selectedAnswerIndex: Int?

    var correctWord: CDWord {
        words[correctAnswerIndex]
    }
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [CDWord] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var questionsAnswered = 0

    private let wordsProvider: WordsProvider
    private var cancellables: Set<AnyCancellable> = []
    private var originalWords: [CDWord] = []
    private var usedWords: Set<CDWord> = []

    init(wordsProvider: WordsProvider) {
        self.wordsProvider = wordsProvider
        self.correctAnswerIndex = Int.random(in: 0...2)
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .answerSelected(let index):
            answerSelected(index)
        case .skipWord:
            skipWord()
        case .restartQuiz:
            restartQuiz()
        case .dismiss:
            dismissPublisher.send()
        }
    }

    private func answerSelected(_ index: Int) {
        selectedAnswerIndex = index
        
        if correctWord.id == words[index].id {
            // Correct answer
            isCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            wordsPlayed.append(correctWord)
            usedWords.insert(correctWord)
            questionsAnswered += 1
            
            // Update score
            score += 100
            
            // Check if quiz is complete
            if usedWords.count >= originalWords.count {
                isQuizComplete = true
            } else {
                // Get next question
                getNextQuestion()
            }
            
            HapticManager.shared.triggerNotification(type: .success)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        } else {
            // Incorrect answer
            isCorrectAnswer = false
            currentStreak = 0 // Reset streak on wrong answer
            
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        }
    }
    
    private func skipWord() {
        // Move current word to end for later
        usedWords.insert(correctWord)
        questionsAnswered += 1
        
        // Penalty for skipping
        score = max(0, score - 25)
        currentStreak = 0
        
        // Check if quiz is complete
        if usedWords.count >= originalWords.count {
            isQuizComplete = true
        } else {
            // Get next question
            getNextQuestion()
        }
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.definitionQuizWordSkipped)
    }
    
    private func getNextQuestion() {
        // Get available words (not used yet)
        let availableWords = originalWords.filter { !usedWords.contains($0) }
        
        if availableWords.count >= 3 {
            // Shuffle and take first 3 words
            let shuffledWords = availableWords.shuffled()
            words = Array(shuffledWords.prefix(3))
            correctAnswerIndex = Int.random(in: 0...2)
            selectedAnswerIndex = nil
            isCorrectAnswer = true
        } else {
            // Not enough words left, quiz is complete
            isQuizComplete = true
        }
    }
    
    private func restartQuiz() {
        // Reset all game state
        originalWords = originalWords.shuffled()
        words = Array(originalWords.prefix(3))
        correctAnswerIndex = Int.random(in: 0...2)
        selectedAnswerIndex = nil
        isCorrectAnswer = true
        correctAnswers = 0
        totalQuestions = originalWords.count
        score = 0
        wordsPlayed = []
        isQuizComplete = false
        currentStreak = 0
        questionsAnswered = 0
        usedWords.removeAll()
        
        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.definitionQuizRestarted)
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.originalWords = words.shuffled()
                self?.words = Array(self?.originalWords.prefix(3) ?? [])
                self?.correctAnswerIndex = Int.random(in: 0...2)
                self?.totalQuestions = words.count
            }
            .store(in: &cancellables)
    }
}

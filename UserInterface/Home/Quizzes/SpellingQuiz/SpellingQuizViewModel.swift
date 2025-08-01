import Foundation
import Combine

final class SpellingQuizViewModel: BaseViewModel {

    enum Input {
        case confirmAnswer
        case skipWord
        case restartQuiz
        case dismiss
    }

    @Published var answerTextField = ""

    @Published private(set) var words: [CDWord] = []
    @Published private(set) var randomWord: CDWord?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var attemptCount = 0
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [CDWord] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var isShowingHint = false
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0

    private let wordsProvider: WordsProvider
    private var cancellables: Set<AnyCancellable> = []
    private var originalWords: [CDWord] = []

    init(wordsProvider: WordsProvider) {
        self.wordsProvider = wordsProvider
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .confirmAnswer:
            confirmAnswer()
        case .skipWord:
            skipWord()
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
            // Correct answer
            isCorrectAnswer = true
            answerTextField = ""
            words.remove(at: wordIndex)
            attemptCount = 0
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            wordsPlayed.append(randomWord)
            isShowingHint = false // Reset hint for next question
            
            // Update score (bonus for fewer attempts)
            let attemptBonus = max(0, 3 - attemptCount) * 10
            score += 100 + attemptBonus
            
            if !words.isEmpty {
                self.randomWord = words.randomElement()
            } else {
                self.randomWord = nil
                isQuizComplete = true
            }
            
            HapticManager.shared.triggerNotification(type: .success)
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
            
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        }
    }
    
    private func skipWord() {
        guard let randomWord else { return }
        
        // Move word to end of list for later
        if let wordIndex = words.firstIndex(where: { $0.id == randomWord.id }) {
            let skippedWord = words.remove(at: wordIndex)
            words.append(skippedWord)
        }
        
        // Penalty for skipping
        score = max(0, score - 25)
        currentStreak = 0
        
        // Get next word
        if !words.isEmpty {
            self.randomWord = words.randomElement()
            attemptCount = 0
            isCorrectAnswer = true
            isShowingHint = false
        }
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.spellingQuizWordSkipped)
    }
    
    private func restartQuiz() {
        // Reset all game state
        words = originalWords.shuffled()
        randomWord = words.randomElement()
        answerTextField = ""
        isCorrectAnswer = true
        attemptCount = 0
        correctAnswers = 0
        totalQuestions = originalWords.count
        score = 0
        wordsPlayed = []
        isQuizComplete = false
        isShowingHint = false
        currentStreak = 0
        
        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.spellingQuizRestarted)
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.originalWords = words
                self?.words = words.shuffled()
                self?.randomWord = self?.words.randomElement()
                self?.totalQuestions = words.count
            }
            .store(in: &cancellables)
    }
}

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

    @Published private(set) var words: [any QuizWord] = []
    @Published private(set) var randomWord: (any QuizWord)?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var attemptCount = 0
    @Published private(set) var isShowingCorrectAnswer = false
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [any QuizWord] = []
    @Published private(set) var correctWordIds: [String] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var isShowingHint = false
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var accuracyContributions: [String: Double] = [:] // Track accuracy contribution per word
    @Published private(set) var errorMessage: String?

    private let quizWordsProvider: QuizWordsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalWords: [any QuizWord] = []
    private var feedbackTimer: Timer?
    private var sessionStartTime: Date = Date()
    private let preset: QuizPreset

    init(preset: QuizPreset) {
        self.preset = preset
        super.init()
        setupBindings()
        pauseSharedDictionaryListeners()
    }
    
    deinit {
        DictionaryService.shared.resumeAllListeners()
    }
    
    private func pauseSharedDictionaryListeners() {
        DictionaryService.shared.pauseAllListeners()
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
            // Save current progress if quiz is in progress
            if !isQuizComplete && wordsPlayed.count > 0 {
                saveQuizSession()
            }
            dismissPublisher.send()
        }
    }

    private func confirmAnswer() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.quiz_id == randomWord.quiz_id })
        else { return }

        if answerTextField.lowercased().trimmed == (randomWord.quiz_wordItself.lowercased().trimmed) {
            // Correct answer
            isCorrectAnswer = true
            isShowingCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            
            // Update word difficulty - add 5 points for correct answer
            updateWordScore(randomWord, points: 5)

            wordsPlayed.append(randomWord)
            correctWordIds.append(randomWord.quiz_id)
            isShowingHint = false // Reset hint for next question
            
            // Calculate accuracy contribution based on attempts
            let accuracyContribution: Double
            if attemptCount == 0 {
                accuracyContribution = 1.0 // Perfect on first try
            } else if attemptCount == 1 {
                accuracyContribution = 0.8 // Good on second try
            } else {
                accuracyContribution = 0.5 // Any more attempts: 50% accuracy
            }
            accuracyContributions[randomWord.quiz_id] = accuracyContribution
            
            // Update quiz score - add 5 points for correct answer
            score += 5
            attemptCount = 0

            HapticManager.shared.triggerNotification(type: .success)
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        } else {
            // Incorrect answer
            isCorrectAnswer = false
            attemptCount += 1
            currentStreak = 0 // Reset streak on wrong answer
            // DON'T add to wordsPlayed here - only when answered correctly, skipped, or failed
            
            // Show hint after 2 attempts
            if attemptCount >= 2 {
                isShowingHint = true
            }
            
            // Update quiz score - subtract 2 points for each wrong attempt
            score -= 2
            
            // After 3 attempts, mark word as needs review and add to played list
            if attemptCount >= 3 {
                updateWordScore(randomWord, points: -2)
                wordsPlayed.append(randomWord) // Add to played list when failed
                accuracyContributions[randomWord.quiz_id] = 0.0 // 0% accuracy for failed words
            }
            
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        }
    }
    
    private func skipWord() {
        guard let randomWord else { return }
        
        // Mark skipped word as needs review - subtract 2 points for skipping
        updateWordScore(randomWord, points: -2)

        // Add word to played list when skipped
        wordsPlayed.append(randomWord)
        accuracyContributions[randomWord.quiz_id] = 0.0 // 0% accuracy for skipped words
        
        // Remove word from list (don't move to end)
        if let wordIndex = words.firstIndex(where: { $0.quiz_id == randomWord.quiz_id }) {
            words.remove(at: wordIndex)
        }
        
        // Update quiz score - subtract 2 points for skipping
        score -= 2
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
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.spellingQuizWordSkipped)
    }
    
    private func restartQuiz() {
        // Reset all game state
        let limitedWords = Array(originalWords.shuffled().prefix(preset.wordCount))
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
        accuracyContributions = [:]
        sessionStartTime = Date()
        
        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.spellingQuizRestarted)
    }
    
    private func saveQuizSession() {
        guard wordsPlayed.count > 0 else { return }

        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = wordsPlayed.count > 0 ? accuracyContributions.values.reduce(0, +) / Double(wordsPlayed.count) : 0.0
                
        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.spelling.title,
            score: score,
            correctAnswers: correctAnswers,
            totalWords: wordsPlayed.count, // Use words actually played
            duration: duration,
            accuracy: accuracy,
            wordsPracticed: wordsPlayed,
            correctWordIds: correctWordIds
        )
        
        // Check and schedule notifications after quiz completion
        NotificationService.shared.checkAndScheduleNotifications()
    }

    private func proceedToNextWord() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.quiz_id == randomWord.quiz_id })
        else { return }
        
        // Clear the answer field and remove the current word
        answerTextField = ""
        isShowingHint = false
        attemptCount = 0
        isCorrectAnswer = true
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

    /// Fetches latest data from Core Data
    private func setupBindings() {
        // Get words from the quiz words provider
        let availableWords = quizWordsProvider.getWordsForQuiz(with: preset)

        // Check if we have enough words after filtering
        if availableWords.count < preset.wordCount {
            // Not enough words available after filtering
            self.errorMessage = preset.hardWordsOnly ?
                Loc.Quizzes.noDifficultWordsAvailable.localized :
                Loc.Quizzes.notEnoughWordsAvailable.localized(preset.wordCount)
            return
        }
        
        self.originalWords = availableWords.shuffled()
        // Limit words to the selected count
        let limitedWords = Array(self.originalWords.prefix(self.preset.wordCount))
        self.words = limitedWords
        self.randomWord = self.words.randomElement()
        self.totalQuestions = limitedWords.count
    }

    private func updateWordScore(_ word: any QuizWord, points: Int) {
        if let sharedWord = word as? SharedWord {
            // For shared words, use the async method
            if let userEmail = AuthenticationService.shared.userEmail {
                sharedWord.quiz_updateDifficultyScoreForUser(points, userEmail: userEmail)
            }
        } else {
            // For private words, use the sync method
            word.quiz_updateDifficultyScore(points)
        }
    }
}

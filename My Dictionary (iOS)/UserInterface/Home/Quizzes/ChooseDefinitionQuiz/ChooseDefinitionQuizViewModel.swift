import Foundation
import Combine

final class ChooseDefinitionQuizViewModel: BaseViewModel {

    enum Input {
        case answerSelected(Int)
        case skipWord
        case restartQuiz
        case saveSession
    }

    @Published private(set) var words: [any QuizWord] = []
    @Published private(set) var correctAnswerIndex: Int
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var selectedAnswerIndex: Int?
    @Published private(set) var answerFeedback: AnswerFeedback = .none

    var correctWord: any QuizWord {
        words[correctAnswerIndex]
    }

    let preset: QuizPreset

    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [any QuizWord] = []
    @Published private(set) var correctWordIds: [String] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var questionsAnswered = 0
    @Published private(set) var errorMessage: String?

    private let quizWordsProvider: QuizWordsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalWords: [any QuizWord] = []
    private var usedWords: Set<String> = []
    private var feedbackTimer: Timer?
    private var sessionStartTime: Date = Date()

    init(preset: QuizPreset) {
        self.preset = preset
        self.correctAnswerIndex = Int.random(in: 0...2)
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
        case .answerSelected(let index):
            answerSelected(index)
        case .skipWord:
            skipWord()
        case .restartQuiz:
            restartQuiz()
        case .saveSession:
            saveQuizSession()
        }
    }

    private func answerSelected(_ index: Int) {
        guard !isQuizComplete else { return }
        
        selectedAnswerIndex = index
        wordsPlayed.append(correctWord)
        usedWords.insert(correctWord.quiz_id)
        questionsAnswered += 1
        
        // Check if answer is correct
        if correctWord.quiz_id == words[index].quiz_id {
            // Correct answer
            answerFeedback = .correct(index)
            isCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            
            // Update word difficulty - add 5 points for correct answer
            updateWordScore(correctWord, points: 5)

            // Add to correct word IDs for analytics
            correctWordIds.append(correctWord.quiz_id)
            
            // Update quiz score - add 5 points for correct answer
            score += 5
            
            HapticManager.shared.triggerNotification(type: .success)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        } else {
            // Incorrect answer
            answerFeedback = .incorrect(index)
            isCorrectAnswer = false
            currentStreak = 0 // Reset streak on wrong answer
            
            // Update word difficulty - subtract 2 points for incorrect answer
            updateWordScore(correctWord, points: -2)

            // Update quiz score - subtract 2 points for incorrect answer
            score -= 2
            
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        }

        // Check if quiz is complete immediately after answering
        if questionsAnswered >= preset.wordCount {
            scheduleQuizCompletion()
        } else {
            scheduleNextQuestion()
        }
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
    
    private func skipWord() {
        // Mark current word as needs review - subtract 2 points for skipping
        updateWordScore(correctWord, points: -2)

        // Move current word to end for later and add to wordsPlayed
        usedWords.insert(correctWord.quiz_id)
        wordsPlayed.append(correctWord)
        questionsAnswered += 1
        
        // Update quiz score - subtract 2 points for skipping
        score -= 2
        currentStreak = 0
        
        // Check if quiz is complete (use wordCount instead of originalWords.count)
        if questionsAnswered >= preset.wordCount {
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next question
            getNextQuestion()
        }
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.definitionQuizWordSkipped)
    }
    
    private func getNextQuestion() {
        // Check if we've reached the word count limit
        if questionsAnswered >= preset.wordCount {
            isQuizComplete = true
            saveQuizSession()
            return
        }
        
        // Get the next word to use as correct answer (not used yet)
        let availableCorrectWords = originalWords.filter { !usedWords.contains($0.quiz_id) }
        
        if availableCorrectWords.isEmpty {
            // No more words to use as correct answers, quiz is complete
            isQuizComplete = true
            saveQuizSession()
            return
        }
        
        // Take the first available word as correct answer
        let correctWord = availableCorrectWords.first!
        
        // Create array with correct word first
        var newWords = [correctWord]
        
        // Add 2 more words as incorrect options (can reuse words that aren't the correct word)
        let remainingWords = originalWords.filter { $0.quiz_id != correctWord.quiz_id }
        if remainingWords.count >= 2 {
            let shuffledRemaining = remainingWords.shuffled()
            newWords.append(contentsOf: shuffledRemaining.prefix(2))
        } else {
            // If not enough words, just use what we have
            newWords.append(contentsOf: remainingWords)
        }
        
        // Ensure we always have exactly 3 words
        while newWords.count < 3 {
            // If we don't have enough words, reuse some words
            let reusableWords = originalWords.filter { $0.quiz_id != correctWord.quiz_id }
            if let additionalWord = reusableWords.first {
                newWords.append(additionalWord)
            }
        }
        
        // Shuffle the options so correct answer isn't always first
        let correctWordInArray = newWords[0]
        newWords.shuffle()
        correctAnswerIndex = newWords.firstIndex(where: { $0.quiz_id == correctWordInArray.quiz_id }) ?? 0
        words = newWords
        selectedAnswerIndex = nil
        isCorrectAnswer = true
    }
    
    private func restartQuiz() {
        // Clear any pending timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        // Reset all game state
        originalWords = originalWords.shuffled()
        selectedAnswerIndex = nil
        isCorrectAnswer = true
        answerFeedback = .none
        correctAnswers = 0
        score = 0
        wordsPlayed = []
        correctWordIds = []
        isQuizComplete = false
        currentStreak = 0
        questionsAnswered = 0
        usedWords.removeAll()
        sessionStartTime = Date()
        
        // Set up the first question
        getNextQuestion()
        
        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.definitionQuizRestarted)
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
        
        originalWords = availableWords.shuffled()
        // Set up the first question
        self.getNextQuestion()
    }

    private func scheduleNextQuestion() {
        // Clear any existing timer
        feedbackTimer?.invalidate()
        
        // Schedule next question after 1.5 seconds
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.moveToNextQuestion()
            }
        }
    }
    
    private func moveToNextQuestion() {
        // Reset feedback
        answerFeedback = .none
        selectedAnswerIndex = nil
        isCorrectAnswer = true
        
        // Get next question (quiz completion is already checked in answerSelected)
        getNextQuestion()
    }
    
    private func saveQuizSession() {
        guard wordsPlayed.count > 0 else { return }

        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = wordsPlayed.count > 0 ? Double(correctAnswers) / Double(wordsPlayed.count) : 0.0
        
        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.chooseDefinition.rawValue,
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

    private func scheduleQuizCompletion() {
        // Clear any existing timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil
        
        // Schedule quiz completion after 1.5 seconds
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.isQuizComplete = true
                self?.saveQuizSession()
            }
        }
    }
}

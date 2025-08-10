import Foundation
import Combine

enum AnswerFeedback: Equatable {
    case none
    case correct(Int)
    case incorrect(Int)
}

final class ChooseDefinitionQuizViewModel: BaseViewModel {

    enum Input {
        case answerSelected(Int)
        case skipWord
        case restartQuiz
        case saveSession
    }

    @Published private(set) var words: [CDWord] = []
    @Published private(set) var correctAnswerIndex: Int
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var selectedAnswerIndex: Int?
    @Published private(set) var answerFeedback: AnswerFeedback = .none

    var correctWord: CDWord {
        words[correctAnswerIndex]
    }

    let wordCount: Int
    let hardWordsOnly: Bool

    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var score = 0
    @Published private(set) var wordsPlayed: [CDWord] = []
    @Published private(set) var correctWordIds: [String] = []
    @Published private(set) var isQuizComplete = false
    
    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var questionsAnswered = 0
    @Published private(set) var errorMessage: String?

    private let wordsProvider: WordsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalWords: [CDWord] = []
    private var usedWords: Set<CDWord> = []
    private var feedbackTimer: Timer?
    private var sessionStartTime: Date = Date()

    init(
        wordCount: Int,
        hardWordsOnly: Bool
    ) {
        self.wordCount = wordCount
        self.hardWordsOnly = hardWordsOnly
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
        case .saveSession:
            saveQuizSession()
        }
    }

    private func answerSelected(_ index: Int) {
        selectedAnswerIndex = index
        wordsPlayed.append(correctWord)
        usedWords.insert(correctWord)
        questionsAnswered += 1

        if correctWord.id == words[index].id {
            // Correct answer
            answerFeedback = .correct(index)
            isCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            correctWordIds.append(correctWord.id?.uuidString ?? "")

            // Update score
            score += 100

            HapticManager.shared.triggerNotification(type: .success)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        } else {
            // Incorrect answer - automatic penalty and progression
            answerFeedback = .incorrect(index)
            isCorrectAnswer = false
            currentStreak = 0 // Reset streak on wrong answer
            updateWordDifficultyLevel(word: correctWord, level: 2)
            // Penalty
            score = max(0, score - 25)

            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        }

        // Check if quiz is complete immediately after answering
        if questionsAnswered >= wordCount {
            scheduleQuizCompletion()
        } else {
            scheduleNextQuestion()
        }
    }
    
    private func skipWord() {
        // Mark current word as needs review
        updateWordDifficultyLevel(word: correctWord, level: 2)
        
        // Move current word to end for later and add to wordsPlayed
        usedWords.insert(correctWord)
        wordsPlayed.append(correctWord)
        questionsAnswered += 1
        
        // Penalty for skipping
        score = max(0, score - 25)
        currentStreak = 0
        
        // Check if quiz is complete (use wordCount instead of originalWords.count)
        if questionsAnswered >= wordCount {
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next question
            getNextQuestion()
        }
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.definitionQuizWordSkipped)
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
    
    private func getNextQuestion() {
        // Check if we've reached the word count limit
        if questionsAnswered >= wordCount {
            isQuizComplete = true
            saveQuizSession()
            return
        }
        
        // Get the next word to use as correct answer (not used yet)
        let availableCorrectWords = originalWords.filter { !usedWords.contains($0) }
        
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
        let remainingWords = originalWords.filter { $0.id != correctWord.id }
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
            let reusableWords = originalWords.filter { $0.id != correctWord.id }
            if let additionalWord = reusableWords.first {
                newWords.append(additionalWord)
            }
        }
        
        // Shuffle the options so correct answer isn't always first
        let correctWordInArray = newWords[0]
        newWords.shuffle()
        correctAnswerIndex = newWords.firstIndex(of: correctWordInArray) ?? 0
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
        wordsProvider.$words
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                guard let self else { return }
                
                // Filter words based on hardWordsOnly
                let filteredWords = hardWordsOnly ? words.filter { $0.difficultyLevel == 2 } : words
                
                // Check if we have enough words after filtering
                let minRequiredWords = hardWordsOnly ? 1 : self.wordCount // Allow 1 word for hard words mode
                if filteredWords.count < minRequiredWords {
                    // Not enough words available after filtering
                    self.errorMessage = hardWordsOnly ? 
                        "No difficult words available for quiz" :
                        "Not enough words available. Need at least \(minRequiredWords) words for the quiz."
                    return
                }
                
                originalWords = filteredWords.shuffled()
                // Set up the first question
                self.getNextQuestion()
            }
            .store(in: &cancellables)
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
        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = wordsPlayed.count > 0 ? Double(correctAnswers) / Double(wordsPlayed.count) : 0.0
        
        quizAnalyticsService.saveQuizSession(
            quizType: "definition",
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

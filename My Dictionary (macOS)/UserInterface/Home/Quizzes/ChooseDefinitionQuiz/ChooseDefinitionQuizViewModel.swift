import Foundation
import Combine

final class ChooseDefinitionQuizViewModel: BaseViewModel {

    enum Input {
        case answerSelected(Int)
        case skipItem
        case restartQuiz
        case saveSession
    }

    @Published private(set) var items: [any Quizable] = []
    @Published private(set) var correctAnswerIndex: Int
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var selectedAnswerIndex: Int?
    @Published private(set) var answerFeedback: AnswerFeedback = .none

    var correctItem: any Quizable {
        items[correctAnswerIndex]
    }

    let preset: QuizPreset

    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var score = 0
    @Published private(set) var itemsPlayed: [any Quizable] = []
    @Published private(set) var correctItemIds: [String] = []
    @Published private(set) var isQuizComplete = false

    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var questionsAnswered = 0
    @Published private(set) var errorMessage: String?
    
    // Streak tracking
    @Published private(set) var showStreakAnimation = false
    @Published private(set) var currentDayStreak: Int?

    private let quizItemsProvider: QuizItemsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalItems: [any Quizable] = []
    private var usedItems: Set<String> = []
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
        case .skipItem:
            skipItem()
        case .restartQuiz:
            restartQuiz()
        case .saveSession:
            saveQuizSession()
        }
    }

    private func answerSelected(_ index: Int) {
        guard !isQuizComplete else { return }

        selectedAnswerIndex = index
        itemsPlayed.append(correctItem)
        usedItems.insert(correctItem.quiz_id)
        questionsAnswered += 1

        // Check if answer is correct
        if correctItem.quiz_id == items[index].quiz_id {
            // Correct answer
            answerFeedback = .correct(index)
            isCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)

            // Update word difficulty - add 5 points for correct answer
            updateItemScore(correctItem, points: 5)

            // Add to correct word IDs for analytics
            correctItemIds.append(correctItem.quiz_id)

            // Update quiz score - add 5 points for correct answer
            score += 5

            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        } else {
            // Incorrect answer
            answerFeedback = .incorrect(index)
            isCorrectAnswer = false
            currentStreak = 0 // Reset streak on wrong answer

            // Update word difficulty - subtract 2 points for incorrect answer
            updateItemScore(correctItem, points: -2)

            // Update quiz score - subtract 2 points for incorrect answer
            score -= 2

            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        }

        // Check if quiz is complete immediately after answering
        if questionsAnswered >= preset.itemCount {
            scheduleQuizCompletion()
        } else {
            scheduleNextQuestion()
        }
    }

    private func updateItemScore(_ item: any Quizable, points: Int) {
        if let sharedWord = item as? SharedWord {
            // For shared items, use the async method
            if let userEmail = AuthenticationService.shared.userEmail {
                sharedWord.quiz_updateDifficultyScoreForUser(points, userEmail: userEmail)
            }
        } else {
            // For private items, use the sync method
            item.quiz_updateDifficultyScore(points)
        }
    }

    private func skipItem() {
        // Mark current word as needs review - subtract 2 points for skipping
        updateItemScore(correctItem, points: -2)

        // Move current word to end for later and add to itemsPlayed
        usedItems.insert(correctItem.quiz_id)
        itemsPlayed.append(correctItem)
        questionsAnswered += 1

        // Update quiz score - subtract 2 points for skipping
        score -= 2
        currentStreak = 0

        // Check if quiz is complete (use itemCount instead of originalItems.count)
        if questionsAnswered >= preset.itemCount {
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next question
            getNextQuestion()
        }

        AnalyticsService.shared.logEvent(.definitionQuizWordSkipped)
    }

    private func getNextQuestion() {
        // Check if we've reached the word count limit
        if questionsAnswered >= preset.itemCount {
            isQuizComplete = true
            saveQuizSession()
            return
        }

        // Get the next word to use as correct answer (not used yet)
        let availableCorrectItems = originalItems.filter { !usedItems.contains($0.quiz_id) }

        if availableCorrectItems.isEmpty {
            // No more items to use as correct answers, quiz is complete
            isQuizComplete = true
            saveQuizSession()
            return
        }

        // Take the first available word as correct answer
        let correctItem = availableCorrectItems.first!

        // Create array with correct word first
        var newItems = [correctItem]

        // Add 2 more items as incorrect options with same part of speech to prevent cheating
        let correctPartOfSpeech = correctItem.quiz_partOfSpeech
        let remainingItems = originalItems.filter { $0.quiz_id != correctItem.quiz_id }
        
        // First, try to find items with the same part of speech
        let samePartOfSpeechItems = remainingItems.filter { $0.quiz_partOfSpeech == correctPartOfSpeech }

        if samePartOfSpeechItems.count >= 2 {
            // Use items with same part of speech as distractors
            let shuffledSamePOS = samePartOfSpeechItems.shuffled()
            newItems.append(contentsOf: shuffledSamePOS.prefix(2))
        } else if samePartOfSpeechItems.count == 1 {
            // Use the one same POS item + one random item
            newItems.append(samePartOfSpeechItems[0])
            let otherItems = remainingItems.filter { $0.quiz_partOfSpeech != correctPartOfSpeech }
            if let randomOther = otherItems.randomElement() {
                newItems.append(randomOther)
            }
        } else {
            // Fallback: use any remaining items (same as before)
            let shuffledRemaining = remainingItems.shuffled()
            newItems.append(contentsOf: shuffledRemaining.prefix(2))
        }

        // Ensure we always have exactly 3 items
        while newItems.count < 3 {
            // If we don't have enough items, reuse some items
            let reusableItems = originalItems.filter { $0.quiz_id != correctItem.quiz_id }
            if let additionalItem = reusableItems.first {
                newItems.append(additionalItem)
            }
        }

        // Shuffle the options so correct answer isn't always first
        let correctItemInArray = newItems[0]
        newItems.shuffle()
        correctAnswerIndex = newItems.firstIndex(where: { $0.quiz_id == correctItemInArray.quiz_id }) ?? 0
        items = newItems
        selectedAnswerIndex = nil
        isCorrectAnswer = true
    }

    private func restartQuiz() {
        // Clear any pending timer
        feedbackTimer?.invalidate()
        feedbackTimer = nil

        // Reset all game state
        originalItems = originalItems.shuffled()
        selectedAnswerIndex = nil
        isCorrectAnswer = true
        answerFeedback = .none
        correctAnswers = 0
        score = 0
        itemsPlayed = []
        correctItemIds = []
        isQuizComplete = false
        currentStreak = 0
        questionsAnswered = 0
        usedItems.removeAll()
        sessionStartTime = Date()
        showStreakAnimation = false
        currentDayStreak = nil

        // Set up the first question
        getNextQuestion()

        AnalyticsService.shared.logEvent(.definitionQuizRestarted)
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        // Get items from the quiz items provider
        let availableItems = quizItemsProvider.getItemsForQuiz(with: preset)

        // Check if we have enough items after filtering
        if availableItems.count < preset.itemCount {
            // Not enough items available after filtering
            self.errorMessage = preset.hardItemsOnly
            ? Loc.Quizzes.QuizActions.noDifficultWordsAvailable
            : Loc.Quizzes.notEnoughWordsAvailable(preset.itemCount)
            return
        }

        originalItems = availableItems.shuffled()
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
        guard itemsPlayed.count > 0 else { return }
        
        // Check if this is the first quiz today before saving
        let wasFirstQuizToday = quizAnalyticsService.isFirstQuizToday()

        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = itemsPlayed.count > 0 ? Double(correctAnswers) / Double(itemsPlayed.count) : 0.0

        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.chooseDefinition.rawValue,
            score: score,
            correctAnswers: correctAnswers,
            totalItems: itemsPlayed.count, // Use items actually played
            duration: duration,
            accuracy: accuracy,
            itemsPracticed: itemsPlayed,
            correctItemIds: correctItemIds
        )
        
        // If this was the first quiz today, calculate streak and show animation
        if wasFirstQuizToday {
            let newStreak = quizAnalyticsService.calculateCurrentStreak()
            showStreakAnimation = true
            currentDayStreak = newStreak
        }

        // Check and schedule notifications after quiz completion
        NotificationService.shared.scheduleNotificationsOnAppExit()
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

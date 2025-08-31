import Foundation
import Combine

final class SpellingQuizViewModel: BaseViewModel {

    enum Input {
        case confirmAnswer
        case skipItem
        case nextItem
        case restartQuiz
        case dismiss
    }

    @Published var answerTextField = ""

    @Published private(set) var items: [any Quizable] = []
    @Published private(set) var randomItem: (any Quizable)?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var attemptCount = 0
    @Published private(set) var isShowingCorrectAnswer = false
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var itemsPlayed: [any Quizable] = []
    @Published private(set) var correctItemIds: [String] = []
    @Published private(set) var isQuizComplete = false
    @Published private(set) var isLastQuestion = false
    
    // Game state
    @Published private(set) var isShowingHint = false
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var accuracyContributions: [String: Double] = [:] // Track accuracy contribution per item
    @Published private(set) var errorMessage: String?

    private let quizItemsProvider: QuizItemsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalItems: [any Quizable] = []
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
        case .skipItem:
            skipItem()
        case .nextItem:
            proceedToNextItem()
        case .restartQuiz:
            restartQuiz()
        case .dismiss:
            // Save current progress if quiz is in progress
            if !isQuizComplete && itemsPlayed.count > 0 {
                saveQuizSession()
            }
            dismissPublisher.send()
        }
    }

    private func confirmAnswer() {
        guard let randomItem,
              let itemIndex = items.firstIndex(where: { $0.quiz_id == randomItem.quiz_id })
        else { return }

        if answerTextField.lowercased().trimmed == (randomItem.quiz_text.lowercased().trimmed) {
            // Correct answer
            isCorrectAnswer = true
            isShowingCorrectAnswer = true
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            
            // Update item difficulty - add 5 points for correct answer
            updateItemScore(randomItem, points: 5)

            itemsPlayed.append(randomItem)
            correctItemIds.append(randomItem.quiz_id)
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
            accuracyContributions[randomItem.quiz_id] = accuracyContribution
            
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
            // DON'T add to itemsPlayed here - only when answered correctly, skipped, or failed
            
            // Show hint after 2 attempts
            if attemptCount >= 2 {
                isShowingHint = true
            }
            
            // Update quiz score - subtract 2 points for each wrong attempt
            score -= 2
            
            // After 3 attempts, mark item as needs review and add to played list
            if attemptCount >= 3 {
                updateItemScore(randomItem, points: -2)
                itemsPlayed.append(randomItem) // Add to played list when failed
                accuracyContributions[randomItem.quiz_id] = 0.0 // 0% accuracy for failed items
            }
            
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        }
    }
    
    private func skipItem() {
        guard let randomItem else { return }
        
        // Mark skipped item as needs review - subtract 2 points for skipping
        updateItemScore(randomItem, points: -2)

        // Add item to played list when skipped
        itemsPlayed.append(randomItem)
        accuracyContributions[randomItem.quiz_id] = 0.0 // 0% accuracy for skipped items
        
        // Remove item from list (don't move to end)
        if let itemIndex = items.firstIndex(where: { $0.quiz_id == randomItem.quiz_id }) {
            items.remove(at: itemIndex)
        }
        
        // Update quiz score - subtract 2 points for skipping
        score -= 2
        currentStreak = 0
        answerTextField = ""

        // Check if quiz is complete
        if items.isEmpty {
            self.randomItem = nil
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next item
            self.randomItem = items.randomElement()
            attemptCount = 0
            isCorrectAnswer = true
            isShowingHint = false
        }
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.spellingQuizWordSkipped)
    }
    
    private func restartQuiz() {
        // Reset all game state
        items = originalItems.shuffled()
        randomItem = items.randomElement()
        answerTextField = ""
        isCorrectAnswer = true
        attemptCount = 0
        correctAnswers = 0
        totalQuestions = preset.itemCount
        score = 0
        itemsPlayed = []
        correctItemIds = []
        isQuizComplete = false
        isLastQuestion = false
        isShowingHint = false
        isShowingCorrectAnswer = false
        currentStreak = 0
        accuracyContributions = [:]
        sessionStartTime = Date()
        
        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.spellingQuizRestarted)
    }
    
    private func saveQuizSession() {
        guard itemsPlayed.count > 0 else { return }

        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = itemsPlayed.count > 0 ? accuracyContributions.values.reduce(0, +) / Double(itemsPlayed.count) : 0.0
                
        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.spelling.rawValue,
            score: score,
            correctAnswers: correctAnswers,
            totalItems: itemsPlayed.count, // Use items actually played
            duration: duration,
            accuracy: accuracy,
            itemsPracticed: itemsPlayed,
            correctItemIds: correctItemIds
        )
        
        // Check and schedule notifications after quiz completion
        NotificationService.shared.checkAndScheduleNotifications()
    }

    private func proceedToNextItem() {
        guard let randomItem,
              let itemIndex = items.firstIndex(where: { $0.quiz_id == randomItem.quiz_id })
        else { return }
        
        // Clear the answer field and remove the current item
        answerTextField = ""
        isShowingHint = false
        attemptCount = 0
        isCorrectAnswer = true
        items.remove(at: itemIndex)
        isShowingCorrectAnswer = false
        
        // Check if we've reached the target item count
        if itemsPlayed.count >= preset.itemCount {
            self.randomItem = nil
            isQuizComplete = true
            saveQuizSession()
        } else if !items.isEmpty {
            // Move to next item
            self.randomItem = items.randomElement()
            // Check if this will be the last question
            isLastQuestion = itemsPlayed.count + 1 >= preset.itemCount
        } else {
            // No more items available, complete quiz
            self.randomItem = nil
            isQuizComplete = true
            saveQuizSession()
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        // Get items from the quiz items provider
        let availableItems = quizItemsProvider.getItemsForQuiz(with: preset)

        // Check if we have enough items after filtering
        if availableItems.count < preset.itemCount {
            // Not enough items available after filtering
            self.errorMessage = preset.hardItemsOnly ?
                Loc.Quizzes.noDifficultWordsAvailable :
                Loc.Quizzes.notEnoughWordsAvailable(preset.itemCount)
            return
        }
        
        self.originalItems = availableItems.shuffled()
        // Use all available items for better variety, but track the target count
        self.items = self.originalItems
        self.randomItem = self.items.randomElement()
        self.totalQuestions = preset.itemCount
    }

    private func updateItemScore(_ item: any Quizable, points: Int) {
        if let sharedItem = item as? SharedWord {
            // For shared items, use the async method
            if let userEmail = AuthenticationService.shared.userEmail {
                sharedItem.quiz_updateDifficultyScoreForUser(points, userEmail: userEmail)
            }
        } else {
            // For private items, use the sync method
            item.quiz_updateDifficultyScore(points)
        }
    }
}

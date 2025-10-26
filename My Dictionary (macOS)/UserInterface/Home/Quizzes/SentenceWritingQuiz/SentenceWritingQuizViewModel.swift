import Foundation
import Combine

final class SentenceWritingQuizViewModel: BaseViewModel {

    enum Input {
        case submitSentence
        case skipItem
        case nextItem
        case restartQuiz
        case dismiss
    }

    @Published var sentenceTextField = ""

    @Published private(set) var items: [any Quizable] = []
    @Published private(set) var currentItem: (any Quizable)?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var isShowingAIEvaluation = false
    @Published private(set) var aiEvaluation: AISentenceEvaluation?
    @Published private(set) var allEvaluations: [AISentenceEvaluation] = []
    @Published private(set) var evaluationMapping: [String: AISentenceEvaluation] = [:]
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var itemsPlayed: [any Quizable] = []
    @Published private(set) var correctItemIds: [String] = []
    @Published private(set) var isQuizComplete = false
    @Published private(set) var isLastQuestion = false
    @Published private(set) var isEvaluatingAllSentences = false
    
    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var accuracyContributions: [String: Double] = [:]
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let quizItemsProvider: QuizItemsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private let subscriptionService: SubscriptionService = .shared
    private let aiService: AIService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalItems: [any Quizable] = []
    private var feedbackTimer: Timer?
    private var sessionStartTime: Date = Date()
    private let preset: QuizPreset
    private var userSentences: [(sentence: String, targetWord: String)] = []

    init(preset: QuizPreset) {
        self.preset = preset
        super.init()
        setupBindings()
        pauseSharedDictionaryListeners()
        checkProSubscription()
    }
    
    deinit {
        DictionaryService.shared.resumeAllListeners()
    }
    
    private func pauseSharedDictionaryListeners() {
        DictionaryService.shared.pauseAllListeners()
    }

    func handle(_ input: Input) {
        switch input {
        case .submitSentence:
            submitSentence()
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

    private func checkProSubscription() {
        if subscriptionService.isProUser == false {
            errorMessage = Loc.Ai.AiError.proRequired
        }
    }

    private func submitSentence() {
        guard let currentItem = currentItem,
              !sentenceTextField.trimmed.isEmpty else { return }
        
        // Store the sentence for batch evaluation at the end
        userSentences.append((sentence: sentenceTextField.trimmed, targetWord: currentItem.quiz_text.trimmed.lowercased()))

        // Add item to played list immediately
        itemsPlayed.append(currentItem)
        
        // Reset UI state
        sentenceTextField = ""
        isShowingAIEvaluation = false
        aiEvaluation = nil
        
        // Remove current item from list
        if let itemIndex = items.firstIndex(where: { $0.quiz_id == currentItem.quiz_id }) {
            items.remove(at: itemIndex)
        }
        
        // Check if quiz is complete based on preset item count
        if itemsPlayed.count >= totalQuestions {
            // Quiz is complete - evaluate all sentences at once
            evaluateAllSentences()
        } else {
            // Get next item
            self.currentItem = items.randomElement()
            // Check if this will be the last question
            isLastQuestion = itemsPlayed.count + 1 >= totalQuestions
        }
    }
    
    private func evaluateAllSentences() {
        isEvaluatingAllSentences = true
        isLoading = true
        
        Task {
            do {
                let evaluations = try await aiService.evaluateSentences(sentences: userSentences)
                
                await MainActor.run {
                    self.allEvaluations = evaluations
                    self.isLoading = false
                    self.isEvaluatingAllSentences = false
                    
                    // Create mapping between target words and evaluations
                    self.evaluationMapping.removeAll()
                    for evaluation in evaluations {
                        self.evaluationMapping[evaluation.targetWord.trimmed.lowercased()] = evaluation
                    }
                    
                    // Process all evaluations and calculate scores
                    for evaluation in evaluations {
                        let isCorrect = evaluation.isCorrect
                        
                        if isCorrect {
                            // Correct answer
                            self.correctAnswers += 1
                            self.currentStreak += 1
                            self.bestStreak = max(self.bestStreak, self.currentStreak)
                            
                            // Find the corresponding item and update its score
                            if let item = self.itemsPlayed.first(where: { $0.quiz_text.trimmed.lowercased() == evaluation.targetWord.trimmed.lowercased() }) {
                                self.updateItemScore(item, points: 5)
                                self.correctItemIds.append(item.quiz_id)
                                self.accuracyContributions[item.quiz_id] = 1.0 // 100% accuracy
                            }
                            
                            // Update quiz score - add 5 points for correct answer
                            self.score += 5
                        } else {
                            // Incorrect answer
                            self.currentStreak = 0
                            
                            // Find the corresponding item and update its score
                            if let item = self.itemsPlayed.first(where: { $0.quiz_text.trimmed.lowercased() == evaluation.targetWord.trimmed.lowercased() }) {
                                self.updateItemScore(item, points: -2)
                                self.accuracyContributions[item.quiz_id] = 0.0 // 0% accuracy
                            }
                            
                            // Update quiz score - subtract 2 points for incorrect answer
                            self.score -= 2
                        }
                    }
                    
                    // Show first evaluation
                    if let firstEvaluation = evaluations.first {
                        self.aiEvaluation = firstEvaluation
                        self.isCorrectAnswer = firstEvaluation.isCorrect
                        self.isShowingAIEvaluation = true
                    }
                    
                    self.isQuizComplete = true
                    self.saveQuizSession()
                    
                    HapticManager.shared.triggerNotification(type: .success)
                    AnalyticsService.shared.logEvent(.sentenceWritingQuizAnswerConfirmed)
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.isEvaluatingAllSentences = false
                    self.errorMessage = error.localizedDescription
                    HapticManager.shared.triggerNotification(type: .error)
                }
            }
        }
    }
    
    private func skipItem() {
        guard let currentItem = currentItem else { return }
        
        // Mark skipped item as needs review - subtract 2 points for skipping
        updateItemScore(currentItem, points: -2)

        // Add item to played list when skipped
        itemsPlayed.append(currentItem)
        accuracyContributions[currentItem.quiz_id] = 0.0 // 0% accuracy for skipped items
        
        // Remove item from list (don't move to end)
        if let itemIndex = items.firstIndex(where: { $0.quiz_id == currentItem.quiz_id }) {
            items.remove(at: itemIndex)
        }
        
        // Update quiz score - subtract 2 points for skipping
        score -= 2
        currentStreak = 0
        sentenceTextField = ""
        isShowingAIEvaluation = false
        aiEvaluation = nil

        // Check if quiz is complete based on preset item count
        if itemsPlayed.count >= totalQuestions {
            self.currentItem = nil
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next item
            self.currentItem = items.randomElement()
        }
        
        HapticManager.shared.triggerNotification(type: .warning)
        AnalyticsService.shared.logEvent(.sentenceWritingQuizWordSkipped)
    }
    
    private func proceedToNextItem() {
        guard let currentItem = currentItem else { return }
        
        // Remove current item from list
        if let itemIndex = items.firstIndex(where: { $0.quiz_id == currentItem.quiz_id }) {
            items.remove(at: itemIndex)
        }
        
        // Reset UI state
        sentenceTextField = ""
        isShowingAIEvaluation = false
        aiEvaluation = nil
        isCorrectAnswer = true
        
        // Check if quiz is complete based on preset item count
        if itemsPlayed.count >= totalQuestions {
            self.currentItem = nil
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next item
            self.currentItem = items.randomElement()
            // Check if this will be the last question
            isLastQuestion = itemsPlayed.count + 1 >= totalQuestions
        }
    }
    
    private func scheduleNextItem() {
        // Show evaluation for 3 seconds before moving to next item
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.proceedToNextItem()
        }
    }
    
    private func restartQuiz() {
        // Reset all game state
        items = originalItems.shuffled()
        currentItem = items.randomElement()
        sentenceTextField = ""
        isCorrectAnswer = true
        correctAnswers = 0
        totalQuestions = preset.itemCount
        score = 0
        itemsPlayed = []
        correctItemIds = []
        isQuizComplete = false
        isLastQuestion = false
        isShowingAIEvaluation = false
        aiEvaluation = nil
        allEvaluations = []
        evaluationMapping = [:]
        currentStreak = 0
        accuracyContributions = [:]
        sessionStartTime = Date()
        isLoading = false
        isEvaluatingAllSentences = false
        userSentences = []
        
        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.sentenceWritingQuizRestarted)
    }
    
    private func saveQuizSession() {
        guard itemsPlayed.count > 0 else { return }

        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = itemsPlayed.count > 0 ? accuracyContributions.values.reduce(0, +) / Double(itemsPlayed.count) : 0.0
                
        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.sentenceWriting.rawValue,
            score: score,
            correctAnswers: correctAnswers,
            totalItems: itemsPlayed.count,
            duration: duration,
            accuracy: accuracy,
            itemsPracticed: itemsPlayed,
            correctItemIds: correctItemIds
        )
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
        self.currentItem = self.items.randomElement()
        self.totalQuestions = preset.itemCount
    }
}

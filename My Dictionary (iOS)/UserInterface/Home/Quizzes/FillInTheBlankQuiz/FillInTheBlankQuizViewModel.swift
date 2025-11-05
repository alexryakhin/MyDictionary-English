import Foundation
import Combine

final class FillInTheBlankQuizViewModel: BaseViewModel {

    enum Input {
        case selectOption(Int)
        case submitAnswer
        case skipItem
        case nextItem
        case restartQuiz
        case retry
        case dismiss
    }
    
    enum LoadingStatus: Hashable {
        case initializing
        case generatingFirstStory
        case prefetching
        case ready
        case error(String)
    }

    @Published private(set) var items: [any Quizable] = []
    @Published private(set) var currentItem: (any Quizable)?
    @Published private(set) var selectedOptionIndex: Int?
    @Published private(set) var isAnswerSubmitted = false
    @Published private(set) var isAnswerCorrect = true
    @Published private(set) var correctAnswerIndex: Int = 0
    @Published private(set) var aiStory: AIFillInTheBlankStory?
    @Published private(set) var allStories: [AIFillInTheBlankStory] = []
    @Published private(set) var shuffledOptions: [AIFillInTheBlankOption] = []
    // Map to store stories by item ID for better synchronization
    private var storiesByItemId: [String: AIFillInTheBlankStory] = [:]
    @Published private(set) var loadingStatus: LoadingStatus = .initializing
    @Published private(set) var isLastQuestion = false
    
    // Game progress tracking
    @Published private(set) var correctAnswers = 0
    @Published private(set) var totalQuestions = 0
    @Published private(set) var score = 0
    @Published private(set) var itemsPlayed: [any Quizable] = []
    @Published private(set) var correctItemIds: [String] = []
    @Published private(set) var isQuizComplete = false

    // Game state
    @Published private(set) var currentStreak = 0
    @Published private(set) var bestStreak = 0
    @Published private(set) var accuracyContributions: [String: Double] = [:]
    
    // Streak tracking
    @Published private(set) var showStreakAnimation = false
    @Published private(set) var currentDayStreak: Int?

    private let quizItemsProvider: QuizItemsProvider = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    private let aiService: AIService = .shared
    private var cancellables = Set<AnyCancellable>()
    private var originalItems: [any Quizable] = []
    private var feedbackTimer: Timer?
    private var sessionStartTime: Date = Date()
    private let preset: QuizPreset
    private var storyIndex = 0
    private var currentQuestionIndex = 0
    private var prefetchTask: Task<Void, Never>?
    private var waitingForItemId: String? // Added to track which item is waiting for a story

    init(preset: QuizPreset) {
        self.preset = preset
        super.init()
        loadingStatus = .initializing // Start with initializing state
        setupBindings()
        pauseSharedDictionaryListeners()
    }

    deinit {
        DictionaryService.shared.resumeAllListeners()
        prefetchTask?.cancel()
    }

    private func pauseSharedDictionaryListeners() {
        DictionaryService.shared.pauseAllListeners()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectOption(let index):
            selectOption(index)
        case .submitAnswer:
            submitAnswer()
        case .skipItem:
            skipItem()
        case .nextItem:
            proceedToNextItem()
        case .restartQuiz:
            restartQuiz()
        case .retry:
            retryCurrentOperation()
        case .dismiss:
            // Save current progress if quiz is in progress
            if !isQuizComplete && itemsPlayed.count > 0 {
                saveQuizSession()
            }
            dismissPublisher.send()
        }
    }

    private func selectOption(_ index: Int) {
        guard !isAnswerSubmitted else { return }
        selectedOptionIndex = index
    }

    private func submitAnswer() {
        guard let selectedOptionIndex = selectedOptionIndex,
              let currentItem = currentItem,
              !isAnswerSubmitted else { return }

        isAnswerSubmitted = true
        let isCorrect = selectedOptionIndex == correctAnswerIndex
        isAnswerCorrect = isCorrect

        if isCorrect {
            // Correct answer
            correctAnswers += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)

            // Update item difficulty - add 5 points for correct answer
            self.updateItemScore(currentItem, points: 5)

            self.itemsPlayed.append(currentItem)
            self.correctItemIds.append(currentItem.quiz_id)
            self.accuracyContributions[currentItem.quiz_id] = 1.0 // 100% accuracy

            // Update quiz score - add 5 points for correct answer
            self.score += 5

            HapticManager.shared.triggerNotification(type: .success)
            AnalyticsService.shared.logEvent(.fillInTheBlankQuizAnswerConfirmed)
        } else {
            // Incorrect answer
            self.currentStreak = 0

            // Update item difficulty - subtract 2 points for incorrect answer
            self.updateItemScore(currentItem, points: -2)

            self.itemsPlayed.append(currentItem)
            self.accuracyContributions[currentItem.quiz_id] = 0.0 // 0% accuracy

            // Update quiz score - subtract 2 points for incorrect answer
            self.score -= 2

            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.fillInTheBlankQuizAnswerConfirmed)
        }

        // No timer - user can proceed manually after seeing explanation
    }

    private func skipItem() {
        guard let currentItem = currentItem,
              !isAnswerSubmitted else { return }

        // Treat skipping as a wrong answer - subtract 2 points
        updateItemScore(currentItem, points: -2)

        // Add item to played list when skipped
        itemsPlayed.append(currentItem)
        accuracyContributions[currentItem.quiz_id] = 0.0 // 0% accuracy for skipped items

        // Update quiz score - subtract 2 points for skipping (same as wrong answer)
        score -= 2
        currentStreak = 0
        
        // Mark as answer submitted but incorrect (to show explanation)
        isAnswerSubmitted = true
        isAnswerCorrect = false
        
        // Don't set selectedOptionIndex since no option was selected
        // This way no wrong answer will be highlighted, only the correct one

        HapticManager.shared.triggerNotification(type: .error) // Use error haptic like wrong answer
        AnalyticsService.shared.logEvent(.fillInTheBlankQuizAnswerConfirmed) // Use same event as wrong answer
    }

    private func proceedToNextItem() {
        guard let currentItem = currentItem else { return }

        // Reset UI state
        selectedOptionIndex = nil
        isAnswerSubmitted = false
        isAnswerCorrect = true
        aiStory = nil
        shuffledOptions = []

        // Check if quiz is complete based on preset item count
        if itemsPlayed.count >= totalQuestions {
            self.currentItem = nil
            isQuizComplete = true
            saveQuizSession()
        } else {
            // Get next item
            loadNextItem()
        }
    }

    // Timer removed - user can proceed manually after seeing explanation

    private func loadNextItem() {
        // Use the next item in order (not random) to match the AI story
        guard storyIndex < items.count else { 
            // No more items - quiz should be complete
            if itemsPlayed.count >= totalQuestions {
                isQuizComplete = true
                saveQuizSession()
            }
            return 
        }
        
        // Set the current item FIRST
        let nextItem = items[storyIndex]
        currentItem = nextItem
        
        // Get the story for this item using the item ID
        guard let story = storiesByItemId[nextItem.quiz_id] else {
            // Story not available yet - show loader and wait for prefetch to complete
            loadingStatus = .prefetching
            waitingForItemId = nextItem.quiz_id // Set the waiting item ID
            return
        }
        
        // Story is available, clear waiting state
        loadingStatus = .ready
        waitingForItemId = nil
        
        // Verify the story matches the item
        if story.word.trimmed.lowercased() != nextItem.quiz_text.trimmed.lowercased() {
            print("⚠️ Warning: Story word '\(story.word)' doesn't match item word '\(nextItem.quiz_text)'")
        }
        
        aiStory = story

        // Shuffle the options and track the correct answer
        let originalOptions = story.options
        shuffledOptions = originalOptions.shuffled()

        // Find the correct answer in the shuffled options
        if let correctOption = originalOptions.first(where: { $0.isCorrect }),
           let shuffledIndex = shuffledOptions.firstIndex(where: { $0.text == correctOption.text }) {
            correctAnswerIndex = shuffledIndex
        } else {
            correctAnswerIndex = 0 // Fallback
        }

        storyIndex += 1
        
        // Check if this is the last question
        isLastQuestion = storyIndex >= totalQuestions
        
        // Prefetch the next story ONLY if we haven't reached the end
        if storyIndex < totalQuestions {
            prefetchNextStory()
        }
        // If it's the last question, don't prefetch anything - there's nothing more to prefetch!
    }

    private func restartQuiz() {
        // Reset all game state
        items = Array(originalItems.shuffled().prefix(preset.itemCount))
        currentItem = nil // Will be set when first story is generated
        selectedOptionIndex = nil
        isAnswerSubmitted = false
        isAnswerCorrect = true
        correctAnswers = 0
        // Don't set totalQuestions here - it will be set based on actual AI response
        score = 0
        itemsPlayed = []
        correctItemIds = []
        isQuizComplete = false
        currentStreak = 0
        accuracyContributions = [:]
        sessionStartTime = Date()
        loadingStatus = .initializing
        aiStory = nil
        allStories = []
        storiesByItemId.removeAll()
        shuffledOptions = []
        storyIndex = 0
        isLastQuestion = false
        waitingForItemId = nil
        showStreakAnimation = false
        currentDayStreak = nil

        // Generate first story and start prefetching
        generateFirstStory()

        HapticManager.shared.triggerNotification(type: .success)
        AnalyticsService.shared.logEvent(.fillInTheBlankQuizRestarted)
    }
    
    private func retryCurrentOperation() {
        // Cancel any existing prefetch task
        prefetchTask?.cancel()
        
        // If we're waiting for a specific item, retry prefetching that item
        if let waitingItemId = waitingForItemId,
           let waitingItem = items.first(where: { $0.quiz_id == waitingItemId }) {
            loadingStatus = .prefetching
            prefetchStoryForItem(waitingItem)
        } else {
            // If we're in error state but not waiting for a specific item, restart the quiz
            restartQuiz()
        }
    }
    
    private func prefetchStoryForItem(_ item: any Quizable) {
        prefetchTask = Task {
            do {
                let word = item.quiz_text.trimmed.lowercased()
                let wordLanguage = item.quiz_language
                let story: AIFillInTheBlankStory = try await aiService.request(.fillBlank(
                    word: word,
                    wordLanguage: wordLanguage,
                    meaning: item.getRandomDefinition(),
                    partOfSpeech: item.quiz_partOfSpeech
                ))
                
                await MainActor.run {
                    if !Task.isCancelled {
                        // Store the story in the mapping using the item ID
                        self.storiesByItemId[item.quiz_id] = story
                        self.allStories.append(story)
                        
                        // If we're currently waiting for this story, load the next item
                        if self.waitingForItemId == item.quiz_id {
                            self.loadNextItem()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        // Show error for prefetch failures so user can retry
                        print("Retry prefetch failed for item \(item.quiz_id): \(error.localizedDescription)")
                        self.loadingStatus = .error(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func saveQuizSession() {
        guard itemsPlayed.count > 0 else { return }
        
        // Check if this is the first quiz today before saving
        let wasFirstQuizToday = quizAnalyticsService.isFirstQuizToday()

        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = itemsPlayed.count > 0 ? accuracyContributions.values.reduce(0, +) / Double(itemsPlayed.count) : 0.0

        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.fillInTheBlank.rawValue,
            score: score,
            correctAnswers: correctAnswers,
            totalItems: itemsPlayed.count,
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

    private func generateFirstStory() {
        guard !items.isEmpty else { return }

        Task {
            do {
                loadingStatus = .generatingFirstStory
                let firstItem = items.first!
                let firstWord = firstItem.quiz_text.lowercased()
                let wordLanguage = firstItem.quiz_language
                let story: AIFillInTheBlankStory = try await aiService.request(.fillBlank(
                    word: firstWord,
                    wordLanguage: wordLanguage,
                    meaning: firstItem.getRandomDefinition(),
                    partOfSpeech: firstItem.quiz_partOfSpeech
                ))

                await MainActor.run {
                    self.allStories = [story]
                    self.storiesByItemId[firstItem.quiz_id] = story
                    self.totalQuestions = preset.itemCount // Use preset number
                    self.loadingStatus = .ready
                    self.waitingForItemId = nil

                    // Set the first item and story
                    self.currentItem = firstItem
                    self.aiStory = story

                    // Shuffle the options and track the correct answer
                    let originalOptions = story.options
                    self.shuffledOptions = originalOptions.shuffled()

                    // Find the correct answer in the shuffled options
                    if let correctOption = originalOptions.first(where: { $0.isCorrect }),
                       let shuffledIndex = self.shuffledOptions.firstIndex(where: { $0.text == correctOption.text }) {
                        self.correctAnswerIndex = shuffledIndex
                    } else {
                        self.correctAnswerIndex = 0 // Fallback
                    }

                    self.storyIndex = 1 // Start from the second story next time
                    
                    // Start prefetching the next story
                    self.prefetchNextStory()
                }
            } catch {
                await MainActor.run {
                    self.loadingStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func prefetchNextStory() {
        guard storyIndex < totalQuestions else { return }
        
        // Cancel any existing prefetch task
        prefetchTask?.cancel()
        
        prefetchTask = Task {
            do {
                guard let nextItem = items[safe: storyIndex] ?? items.last else { return }
                // Don't change loading status to prefetching - keep current item visible
                let nextWord = nextItem.quiz_text.trimmed.lowercased()
                let wordLanguage = nextItem.quiz_language
                let story: AIFillInTheBlankStory = try await aiService.request(.fillBlank(
                    word: nextWord,
                    wordLanguage: wordLanguage,
                    meaning: nextItem.getRandomDefinition(),
                    partOfSpeech: nextItem.quiz_partOfSpeech
                ))
                
                await MainActor.run {
                    if !Task.isCancelled {
                        // Store the story in the mapping using the item ID
                        self.storiesByItemId[nextItem.quiz_id] = story
                        self.allStories.append(story)
                        
                        // If we're currently loading and waiting for this story, load the next item
                        if self.waitingForItemId == nextItem.quiz_id {
                            self.loadNextItem()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        // Show error for prefetch failures so user can retry
                        print("Prefetch failed for story \(storyIndex): \(error.localizedDescription)")
                        self.loadingStatus = .error(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func setupBindings() {
        // Get items from the quiz items provider
        let availableItems = quizItemsProvider.getItemsForQuiz(with: preset)

        // Check if we have enough items after filtering
        if availableItems.count < preset.itemCount {
            // Not enough items available after filtering
            self.loadingStatus = .error(preset.hardItemsOnly ?
            Loc.Quizzes.noDifficultWordsAvailable :
            Loc.Quizzes.notEnoughWordsAvailable(preset.itemCount))
            return
        }

        // Shuffle once and take only the number we need
        self.originalItems = availableItems.shuffled()
        self.items = Array(originalItems.prefix(preset.itemCount))
        // Don't set currentItem here - it will be set when first story is generated
        // Don't set totalQuestions here - it will be set based on actual AI response

        // Generate first story and start prefetching
        generateFirstStory()
    }
}

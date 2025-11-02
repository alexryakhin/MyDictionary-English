//
//  StoryLabViewModel.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation
import Combine

final class StoryLabViewModel: BaseViewModel {
    
    enum Input {
        case generateStory(StoryLabConfig)
        case selectPage(Int)
        case nextPage
        case previousPage
        case submitAnswer(pageIndex: Int, questionIndex: Int, answerIndex: Int)
        case addDiscoveredWord(String)
        case finishStory
        case retry
        case dismiss
    }
    
    enum LoadingStatus: Hashable {
        case idle
        case generating
        case ready
        case error(String)
    }
    
    @Published private(set) var loadingStatus: LoadingStatus = .idle
    @Published private(set) var story: AIStoryResponse?
    @Published private(set) var session: StorySession?
    @Published private(set) var errorMessage: String?
    
    // Streak tracking
    @Published private(set) var showStreakAnimation = false
    @Published private(set) var currentDayStreak: Int?
    
    private let aiService: AIService = .shared
    private let wordsProvider: WordsProvider = .shared
    private let sessionService: StoryLabSessionService = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared
    
    private var initialConfig: StoryLabConfig?
    private var sessionStartTime: Date?
    
    /// Optional handler called when a word is saved from the story
    /// Allows attaching saved words to the story session for analytics
    var onWordSaved: ((String) -> Void)?
    
    var config: StoryLabConfig? {
        return initialConfig
    }
    
    convenience init(config: StoryLabConfig) {
        self.init()
        self.initialConfig = config
        // Try to load existing session first, otherwise generate new story
        loadExistingSession(config: config)
    }
    
    private func loadExistingSession(config: StoryLabConfig) {
        // Try to find an incomplete session matching this config
        // Sort by date descending to get most recent first
        let incompleteSessions = sessionService.getIncompleteSessions()
        
        // Find a session that matches the config (prioritize most recent)
        // Match by targetLanguage, cefrLevel, and pageCount
        if let matchingSession = incompleteSessions.first(where: { cdSession in
            guard let sessionConfig = cdSession.config else { return false }
            return sessionConfig.targetLanguage == config.targetLanguage &&
                   sessionConfig.cefrLevel == config.cefrLevel &&
                   sessionConfig.pageCount == config.pageCount &&
                   // Also match savedWords or customText if provided
                   (config.savedWords == nil || sessionConfig.savedWords == config.savedWords) &&
                   (config.customText == nil || sessionConfig.customText == config.customText)
        }),
           let loadedStory = matchingSession.story,
           let loadedStorySession = matchingSession.toStorySession() {
            // Load existing session
            self.story = loadedStory
            self.session = loadedStorySession
            self.initialConfig = matchingSession.config ?? config
            self.loadingStatus = .ready
            // Track session start time when loading existing session
            if sessionStartTime == nil {
                sessionStartTime = Date()
            }
        } else if config.savedWords != nil || config.customText != nil {
            // No existing session found, generate new story
            generateStory(config: config)
        }
    }
    
    func handle(_ input: Input) {
        switch input {
        case .generateStory(let config):
            generateStory(config: config)
        case .selectPage(let pageIndex):
            selectPage(pageIndex)
        case .nextPage:
            nextPage()
        case .previousPage:
            previousPage()
        case .submitAnswer(let pageIndex, let questionIndex, let answerIndex):
            submitAnswer(pageIndex: pageIndex, questionIndex: questionIndex, answerIndex: answerIndex)
        case .addDiscoveredWord(let word):
            addDiscoveredWord(word)
        case .finishStory:
            finishStory()
        case .retry:
            retryGeneration()
        case .dismiss:
            dismissPublisher.send()
        }
    }
    
    private func generateStory(config: StoryLabConfig) {
        guard aiService.canRunQuizToday(.storyLab) else {
            showAlert(withModel: .init(
                title: Loc.Subscription.ProFeatures.aiQuizzes,
                message: Loc.Subscription.ProFeatures.aiQuizzesDescription,
                actionText: Loc.Actions.ok,
                additionalActionText: Loc.Subscription.Paywall.upgradeToPro,
                action: {},
                additionalAction: {
                    PaywallService.shared.presentPaywall(for: .aiQuizzes)
                }
            ))
            return
        }
        guard loadingStatus != .generating else { return }
        
        loadingStatus = .generating
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let storyInput = config.toStoryInput()
                let generatedStory = try await aiService.generateStory(input: storyInput)
                
                self.story = generatedStory
                let newSession = StorySession(story: generatedStory)
                self.session = newSession
                self.initialConfig = config
                self.loadingStatus = .ready
                // Track session start time when generating new story
                self.sessionStartTime = Date()
                
                // Save immediately after generation so user can always return to it
                await saveSession()
            } catch {
                self.errorMessage = error.localizedDescription
                self.loadingStatus = .error(error.localizedDescription)
            }
        }
    }
    
    private func saveSession() async {
        guard let session = session,
              let story = story,
              let config = initialConfig else { return }
        
        do {
            try await StoryLabSessionService.shared.saveOrUpdateSession(session, config: config, story: story)
        } catch {
            print("Error saving story lab session: \(error)")
        }
    }
    
    private func selectPage(_ pageIndex: Int) {
        guard let session = session,
              pageIndex >= 0,
              pageIndex < (story?.pages.count ?? 0) else { return }
        
        var updatedSession = session
        updatedSession.currentPageIndex = pageIndex
        self.session = updatedSession
        
        // Save page navigation
        Task {
            await saveSession()
        }
    }
    
    private func nextPage() {
        guard let session = session,
              let story = story,
              session.currentPageIndex < story.pages.count - 1 else { return }
        
        var updatedSession = session
        updatedSession.currentPageIndex += 1
        self.session = updatedSession
    }
    
    private func previousPage() {
        guard let session = session,
              session.currentPageIndex > 0 else { return }
        
        var updatedSession = session
        updatedSession.currentPageIndex -= 1
        self.session = updatedSession
    }
    
    private func submitAnswer(pageIndex: Int, questionIndex: Int, answerIndex: Int) {
        guard let session = session else { return }
        
        var updatedSession = session
        updatedSession.submitAnswer(forPageIndex: pageIndex, questionIndex: questionIndex, answerIndex: answerIndex)
        self.session = updatedSession
        
        // Save after each answer submission
        Task {
            await saveSession()
        }
        
        // Auto-save when story is completed
        if updatedSession.isComplete {
            finishStory()
        }
    }
    
    private func addDiscoveredWord(_ word: String) {
        guard let session = session else { return }
        
        var updatedSession = session
        updatedSession.addDiscoveredWord(word)
        self.session = updatedSession
    }
    
    private func finishStory() {
        // Final save when completed (though it's already being saved after each answer)
        Task {
            await saveSession()
        }
        
        // Save quiz session to analytics
        saveQuizSessionToAnalytics()
    }
    
    private func saveQuizSessionToAnalytics() {
        guard let session = session,
              session.isComplete,
              let startTime = sessionStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let accuracy = session.totalQuestions > 0 
            ? Double(session.correctAnswers) / Double(session.totalQuestions) 
            : 0.0
        
        // Calculate score using same system as other quizzes
        // +5 points per correct answer, -2 points per incorrect answer
        let score = (session.correctAnswers * 5) - ((session.totalQuestions - session.correctAnswers) * 2)
        
        // Check if this is the first quiz today before saving
        let wasFirstQuizToday = quizAnalyticsService.isFirstQuizToday()
        
        // Ensure we're on main thread for Core Data operations
        // saveQuizSession() requires main thread access
        if Thread.isMainThread {
            // Save quiz session to analytics (Story Lab doesn't use word items)
            quizAnalyticsService.saveQuizSession(
                quizType: Quiz.storyLab.rawValue,
                score: score,
                correctAnswers: session.correctAnswers,
                totalItems: session.totalQuestions,
                duration: duration,
                accuracy: accuracy,
                itemsPracticed: [], // Story Lab doesn't use word/idiom items
                correctItemIds: [] // Story Lab doesn't use word/idiom items
            )
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Save quiz session to analytics (Story Lab doesn't use word items)
                self.quizAnalyticsService.saveQuizSession(
                    quizType: Quiz.storyLab.rawValue,
                    score: score,
                    correctAnswers: session.correctAnswers,
                    totalItems: session.totalQuestions,
                    duration: duration,
                    accuracy: accuracy,
                    itemsPracticed: [], // Story Lab doesn't use word/idiom items
                    correctItemIds: [] // Story Lab doesn't use word/idiom items
                )
            }
        }
        
        // If this was the first quiz today, calculate and update streak
        if wasFirstQuizToday {
            let newStreak = quizAnalyticsService.calculateCurrentStreak()
            currentDayStreak = newStreak
            showStreakAnimation = true
        }
        
        // Check and schedule notifications after quiz completion
        NotificationService.shared.scheduleNotificationsOnAppExit()
    }
    
    private func retryGeneration() {
        errorMessage = nil
        loadingStatus = .idle
        story = nil
        session = nil
        sessionStartTime = nil
        showStreakAnimation = false
        currentDayStreak = nil
    }
    
    var canNavigateNext: Bool {
        guard let session = session, let story = story else { return false }
        return session.currentPageIndex < story.pages.count - 1
    }
    
    var canNavigatePrevious: Bool {
        guard let session = session else { return false }
        return session.currentPageIndex > 0
    }
    
    var currentPage: AIStoryPage? {
        guard let session = session, let story = story else { return nil }
        let pageIndex = session.currentPageIndex
        guard pageIndex < story.pages.count else { return nil }
        return story.pages[pageIndex]
    }
    
    var isCurrentPageQuizComplete: Bool {
        guard let session = session,
              let currentPage = currentPage else { return false }
        
        let pageIndex = session.currentPageIndex
        for (questionIndex, _) in currentPage.questions.enumerated() {
            let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: questionIndex)
            if session.answers[key] == nil {
                return false
            }
        }
        return true
    }
}

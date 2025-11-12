import Foundation

@MainActor
final class StoryLabReadingViewModel: BaseViewModel {

    enum Input {
        case selectPage(Int)
        case nextPage
        case previousPage
        case submitAnswer(pageIndex: Int, questionIndex: Int, answerIndex: Int)
        case addDiscoveredWord(String)
        case finishStory
    }

    @Published private(set) var session: StorySession?
    @Published private(set) var story: AIStoryResponse?
    @Published private(set) var config: StoryLabConfig?
    @Published private(set) var showStreakAnimation = false
    @Published private(set) var currentDayStreak: Int?

    var onWordSaved: ((String) -> Void)?

    private let sessionService: StoryLabSessionService
    private let quizAnalyticsService: QuizAnalyticsService
    private let navigationManager: NavigationManager

    private var sessionId: UUID
    private var sessionStartTime: Date
    private var hasNavigatedToResults = false

    init(
        config: StoryLabReadingConfig,
        sessionService: StoryLabSessionService = .shared,
        quizAnalyticsService: QuizAnalyticsService = .shared,
        navigationManager: NavigationManager = .shared
    ) {
        self.sessionService = sessionService
        self.quizAnalyticsService = quizAnalyticsService
        self.navigationManager = navigationManager
        self.sessionId = config.sessionId
        self.session = config.session
        self.story = config.story
        self.config = config.config
        self.sessionStartTime = Date()
        super.init()

        loadLatestSessionIfNeeded()
    }

    func handle(_ input: Input) {
        switch input {
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
            finishStoryIfNeeded()
        }
    }

    // MARK: - Computed properties

    var canNavigateNext: Bool {
        guard let session, let story else { return false }
        return session.currentPageIndex < story.pages.count - 1
    }

    var canNavigatePrevious: Bool {
        guard let session else { return false }
        return session.currentPageIndex > 0
    }

    var currentPage: AIStoryPage? {
        guard let session, let story else { return nil }
        let pageIndex = session.currentPageIndex
        guard pageIndex < story.pages.count else { return nil }
        return story.pages[pageIndex]
    }

    var isCurrentPageQuizComplete: Bool {
        guard let session, let currentPage else { return false }
        let pageIndex = session.currentPageIndex
        for questionIndex in currentPage.questions.indices {
            let key = StorySession.QuestionKey(pageIndex: pageIndex, questionIndex: questionIndex)
            if session.answers[key] == nil {
                return false
            }
        }
        return true
    }

    // MARK: - Loading

    private func loadLatestSessionIfNeeded() {
        guard let storedSession = sessionService.getSession(by: sessionId) else { return }

        if let latestSession = storedSession.toStorySession() {
            session = latestSession
        }

        if let storedStory = storedSession.story {
            story = storedStory
        }

        if let storedConfig = storedSession.config {
            config = storedConfig
        }
    }

    // MARK: - Navigation

    private func selectPage(_ pageIndex: Int) {
        guard var session,
              let story,
              pageIndex >= 0,
              pageIndex < story.pages.count else { return }

        session.currentPageIndex = pageIndex
        self.session = session
        saveSessionState()
    }

    private func nextPage() {
        guard var session,
              let story,
              session.currentPageIndex < story.pages.count - 1 else { return }

        session.currentPageIndex += 1
        self.session = session
        saveSessionState()
    }

    private func previousPage() {
        guard var session,
              session.currentPageIndex > 0 else { return }

        session.currentPageIndex -= 1
        self.session = session
        saveSessionState()
    }

    private func submitAnswer(pageIndex: Int, questionIndex: Int, answerIndex: Int) {
        guard var session else { return }

        session.submitAnswer(forPageIndex: pageIndex, questionIndex: questionIndex, answerIndex: answerIndex)
        self.session = session

        saveSessionState()

        if session.isComplete {
            finishStoryIfNeeded()
        }
    }

    private func addDiscoveredWord(_ word: String) {
        guard var session else { return }
        session.addDiscoveredWord(word)
        self.session = session
        saveSessionState()
    }

    private func finishStoryIfNeeded() {
        guard let session, session.isComplete, !hasNavigatedToResults else { return }
        Task {
            await saveSession()
            await recordAnalytics(for: session)
            navigateToResults(showStreak: showStreakAnimation, streak: currentDayStreak)
        }
    }

    // MARK: - Persistence

    private func saveSessionState() {
        Task { [weak self] in
            await self?.saveSession()
        }
    }

    private func saveSession() async {
        guard let session, let story, let config else { return }
        do {
            try await sessionService.saveOrUpdateSession(session, config: config, story: story)
        } catch {
            logError("[StoryLabReadingViewModel] Failed to persist session: \(error.localizedDescription)")
        }
    }

    // MARK: - Analytics & Results

    private func recordAnalytics(for session: StorySession) async {
        let duration = Date().timeIntervalSince(sessionStartTime)
        let accuracy = session.totalQuestions > 0 ? Double(session.correctAnswers) / Double(session.totalQuestions) : 0
        let score = (session.correctAnswers * 5) - ((session.totalQuestions - session.correctAnswers) * 2)

        let wasFirstQuizToday = quizAnalyticsService.isFirstQuizToday()

        await MainActor.run {
            quizAnalyticsService.saveQuizSession(
                quizType: Quiz.storyLab.rawValue,
                score: score,
                correctAnswers: session.correctAnswers,
                totalItems: session.totalQuestions,
                duration: duration,
                accuracy: accuracy,
                itemsPracticed: [],
                correctItemIds: []
            )
        }

        if wasFirstQuizToday {
            let streak = quizAnalyticsService.calculateCurrentStreak()
            showStreakAnimation = true
            currentDayStreak = streak
        }

        NotificationService.shared.scheduleNotificationsOnAppExit()
    }

    private func navigateToResults(showStreak: Bool, streak: Int?) {
        guard let session, let story, let config else { return }

        hasNavigatedToResults = true

        let resultsConfig = StoryLabResultsConfig(
            sessionId: session.id,
            showStreak: showStreak,
            currentDayStreak: streak,
            session: session,
            story: story,
            config: config
        )

        navigationManager.navigate(to: .storyLabResults(resultsConfig))
    }
}

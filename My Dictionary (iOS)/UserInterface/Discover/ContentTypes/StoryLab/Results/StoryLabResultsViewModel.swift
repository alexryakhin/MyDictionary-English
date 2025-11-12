import Foundation

@MainActor
final class StoryLabResultsViewModel: BaseViewModel {

    enum Input {
        case refresh
        case setStreakAnimationActive(Bool)
    }

    @Published private(set) var session: StorySession?
    @Published private(set) var story: AIStoryResponse?
    @Published private(set) var config: StoryLabConfig?
    @Published private(set) var showStreakAnimation: Bool
    @Published private(set) var currentDayStreak: Int?

    private let sessionService: StoryLabSessionService
    private let sessionId: UUID

    init(
        config: StoryLabResultsConfig,
        sessionService: StoryLabSessionService = .shared
    ) {
        self.sessionService = sessionService
        self.sessionId = config.sessionId
        self.showStreakAnimation = config.showStreak
        self.currentDayStreak = config.currentDayStreak
        super.init()

        self.session = config.session
        self.story = config.story
        self.config = config.config

        loadLatestSnapshot()
    }

    func handle(_ input: Input) {
        switch input {
        case .refresh:
            loadLatestSnapshot()
        case .setStreakAnimationActive(let isActive):
            showStreakAnimation = isActive
        }
    }

    var score: Int {
        session?.score ?? 0
    }

    var correctAnswers: Int {
        session?.correctAnswers ?? 0
    }

    var totalQuestions: Int {
        session?.totalQuestions ?? 0
    }

    var discoveredWords: [String] {
        Array(session?.discoveredWords ?? []).sorted()
    }

    private func loadLatestSnapshot() {
        guard let storedSession = sessionService.getSession(by: sessionId) else { return }

        if let resolvedSession = storedSession.toStorySession() {
            session = resolvedSession
        }

        if let storedStory = storedSession.story {
            story = storedStory
        }

        if let storedConfig = storedSession.config {
            config = storedConfig
        }
    }
}


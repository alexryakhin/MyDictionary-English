import Foundation

@MainActor
final class StoryLabConfigurationViewModel: BaseViewModel {

    enum LoadingStatus: Equatable {
        case idle
        case generating
        case error(String)
    }

    enum Input {
        case generateStory(StoryLabConfig)
    }

    @Published private(set) var loadingStatus: LoadingStatus = .idle

    private let aiService: AIService
    private let sessionService: StoryLabSessionService
    private let navigationManager: NavigationManager

    init(
        aiService: AIService = .shared,
        sessionService: StoryLabSessionService = .shared,
        navigationManager: NavigationManager = .shared
    ) {
        self.aiService = aiService
        self.sessionService = sessionService
        self.navigationManager = navigationManager
        super.init()
    }

    func handle(_ input: Input) {
        switch input {
        case .generateStory(let config):
            Task { [weak self] in
                await self?.generateStory(config)
            }
        }
    }

    private func generateStory(_ config: StoryLabConfig) async {
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

        do {
            let storyInput = config.toStoryInput()
            let story: AIStoryResponse = try await aiService.request(.story(input: storyInput))

            var session = StorySession(story: story)
            session.currentPageIndex = 0

            try await sessionService.saveOrUpdateSession(session, config: config, story: story)

            let readingConfig = StoryLabReadingConfig(
                sessionId: session.id,
                session: session,
                story: story,
                config: config
            )

            loadingStatus = .idle
            navigationManager.navigate(to: .storyLabReading(readingConfig))
        } catch {
            loadingStatus = .error(error.localizedDescription)
            logError("[StoryLabConfigurationViewModel] Failed to generate story: \(error.localizedDescription)")
        }
    }

    func openSession(_ session: CDStoryLabSession) {
        if session.isComplete {
            if let config = StoryLabResultsConfig(session: session) {
                navigationManager.navigate(to: .storyLabResults(config))
            }
        } else {
            if let config = StoryLabReadingConfig(session: session) {
                navigationManager.navigate(to: .storyLabReading(config))
            }
        }
    }
}

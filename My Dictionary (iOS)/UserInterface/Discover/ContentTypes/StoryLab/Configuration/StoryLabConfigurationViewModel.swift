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
    private let analytics: AnalyticsService

    init(
        aiService: AIService = .shared,
        sessionService: StoryLabSessionService = .shared,
        navigationManager: NavigationManager = .shared,
        analytics: AnalyticsService = .shared
    ) {
        self.aiService = aiService
        self.sessionService = sessionService
        self.navigationManager = navigationManager
        self.analytics = analytics
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
                title: Loc.Subscription.ProFeatures.aiLessons,
                message: Loc.Subscription.ProFeatures.aiLessonsDescription,
                actionText: Loc.Actions.ok,
                additionalActionText: Loc.Subscription.Paywall.upgradeToPro,
                action: {},
                additionalAction: {
                    PaywallService.shared.presentPaywall(for: .aiLessons)
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
            analytics.logEvent(
                .storyLabGenerationSucceeded,
                parameters: generationSuccessParameters(config: config, story: story)
            )
            navigationManager.navigate(to: .storyLabReading(readingConfig))
        } catch {
            loadingStatus = .error(error.localizedDescription)
            logError("[StoryLabConfigurationViewModel] Failed to generate story: \(error.localizedDescription)")
            analytics.logEvent(
                .storyLabGenerationFailed,
                parameters: generationFailureParameters(config: config, error: error)
            )
        }
    }

    func openSession(_ session: CDStoryLabSession) {
        if session.isComplete {
            if let config = StoryLabResultsConfig(session: session) {
                analytics.logEvent(
                    .storyLabSessionOpened,
                    parameters: [
                        "session_id": session.id?.uuidString ?? session.objectID.uriRepresentation().absoluteString,
                        "source": "configuration",
                        "is_complete": 1
                    ]
                )
                navigationManager.navigate(to: .storyLabResults(config))
            }
        } else {
            if let config = StoryLabReadingConfig(session: session) {
                analytics.logEvent(
                    .storyLabSessionOpened,
                    parameters: [
                        "session_id": session.id?.uuidString ?? session.objectID.uriRepresentation().absoluteString,
                        "source": "configuration",
                        "is_complete": 0
                    ]
                )
                navigationManager.navigate(to: .storyLabReading(config))
            }
        }
    }

    private func generationSuccessParameters(config: StoryLabConfig, story: AIStoryResponse) -> [String: Any] {
        var params: [String: Any] = [
            "target_language": config.targetLanguage.rawValue,
            "cefr_level": config.cefrLevel.rawValue,
            "page_count": config.pageCount,
            "word_count": story.metadata.wordCount,
            "pages_generated": story.pages.count
        ]

        if let words = config.savedWords {
            params["saved_words_count"] = words.count
        }

        if let text = config.customText {
            params["custom_text_length"] = text.count
        }

        return params
    }

    private func generationFailureParameters(config: StoryLabConfig, error: Error) -> [String: Any] {
        var params: [String: Any] = [
            "target_language": config.targetLanguage.rawValue,
            "cefr_level": config.cefrLevel.rawValue,
            "page_count": config.pageCount,
            "error": String(error.localizedDescription.prefix(200))
        ]

        if let words = config.savedWords {
            params["saved_words_count"] = words.count
        }

        if let text = config.customText {
            params["custom_text_length"] = text.count
        }

        return params
    }
}

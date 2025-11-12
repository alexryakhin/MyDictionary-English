import Foundation
import Combine

@MainActor
final class StoryLabHistoryViewModel: BaseViewModel {

    @Published private(set) var sessions: [CDStoryLabSession] = []

    private let repository: StoryLabSessionsRepository = .shared
    private let navigationManager: NavigationManager = .shared
    private let analytics: AnalyticsService = .shared
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        bindRepository()
    }

    func handleRefresh() {
        repository.loadSessions()
    }

    func deleteSessions(at indices: IndexSet) {
        repository.deleteSessions(at: indices)
    }

    func navigate(to session: CDStoryLabSession) {
        analytics.logEvent(
            .storyLabSessionOpened,
            parameters: [
                "session_id": session.id?.uuidString ?? session.objectID.uriRepresentation().absoluteString,
                "source": "history",
                "is_complete": session.isComplete ? 1 : 0
            ]
        )
        
        if session.isComplete {
            if let resultsConfig = StoryLabResultsConfig(session: session) {
                navigationManager.navigate(to: .storyLabResults(resultsConfig))
            }
        } else {
            if let readingConfig = StoryLabReadingConfig(session: session) {
                navigationManager.navigate(to: .storyLabReading(readingConfig))
            }
        }
    }

    private func bindRepository() {
        repository.$sessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                self?.sessions = sessions
            }
            .store(in: &cancellables)
    }
}

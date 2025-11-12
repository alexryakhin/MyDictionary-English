import Foundation

struct StoryLabReadingConfig: Hashable {
    let sessionId: UUID
    let session: StorySession?
    let story: AIStoryResponse?
    let config: StoryLabConfig?

    static func == (lhs: StoryLabReadingConfig, rhs: StoryLabReadingConfig) -> Bool {
        lhs.sessionId == rhs.sessionId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
    }
}

struct StoryLabResultsConfig: Hashable {
    let sessionId: UUID
    let showStreak: Bool
    let currentDayStreak: Int?
    let session: StorySession?
    let story: AIStoryResponse?
    let config: StoryLabConfig?

    static func == (lhs: StoryLabResultsConfig, rhs: StoryLabResultsConfig) -> Bool {
        lhs.sessionId == rhs.sessionId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
    }
}

extension StoryLabReadingConfig {
    init?(session: CDStoryLabSession) {
        guard let resolvedSession = session.toStorySession(),
              let story = session.story,
              let config = session.config else {
            return nil
        }

        self.init(
            sessionId: resolvedSession.id,
            session: resolvedSession,
            story: story,
            config: config
        )
    }
}

extension StoryLabResultsConfig {
    init?(session: CDStoryLabSession, showStreak: Bool = false, currentDayStreak: Int? = nil) {
        guard let resolvedSession = session.toStorySession(),
              let story = session.story,
              let config = session.config else {
            return nil
        }

        self.init(
            sessionId: resolvedSession.id,
            showStreak: showStreak,
            currentDayStreak: currentDayStreak,
            session: resolvedSession,
            story: story,
            config: config
        )
    }
}


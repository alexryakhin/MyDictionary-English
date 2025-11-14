import Foundation

@MainActor
final class PronunciationPracticeQuizViewModel: BaseViewModel {

    enum LoadingState: Equatable {
        case loading
        case generating
        case ready
        case error(String)
    }

    struct WordSummary: Identifiable {
        let id = UUID()
        let word: String
        let sentence: String
        var transcript: String = ""
        var isCorrect: Bool?
    }

    private struct PracticeItem {
        let word: any Quizable
        let sentence: String
        let language: InputLanguage
    }

    // MARK: - Published Properties

    @Published private(set) var loadingState: LoadingState = .loading
    @Published private(set) var quizConfig: PronunciationQuizConfig?
    @Published private(set) var wordSummaries: [WordSummary] = []
    @Published private(set) var isQuizComplete: Bool = false
    @Published private(set) var showStreakAnimation: Bool = false
    @Published private(set) var currentDayStreak: Int?

    @Published private(set) var score: Int = 0
    @Published private(set) var correctAnswers: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var currentStreak: Int = 0

    // MARK: - Private Properties

    private let preset: QuizPreset
    private let quizItemsProvider: QuizItemsProvider = .shared
    private let aiService: AIService = .shared
    private let quizAnalyticsService: QuizAnalyticsService = .shared

    private var practiceItems: [PracticeItem] = []
    private var results: [Int: Bool] = [:]
    private var transcripts: [Int: String] = [:]
    private var itemsPlayed: [any Quizable] = []
    private var correctItemIds: [String] = []
    private var accuracyContributionSum: Double = 0
    private var sessionStartTime: Date = Date()
    private var isSavingSession = false

    // MARK: - Init

    init(preset: QuizPreset) {
        self.preset = preset
        super.init()
        generateQuiz()
    }

    // MARK: - Public API

    func handleDismissIfNeeded() {
        guard !isQuizComplete, !itemsPlayed.isEmpty else { return }
        saveQuizSession()
    }

    // MARK: - Setup

    private func generateQuiz() {
        loadingState = .loading
        quizConfig = nil
        practiceItems = []
        wordSummaries = []
        results = [:]
        transcripts = [:]
        itemsPlayed = []
        correctItemIds = []
        accuracyContributionSum = 0
        score = 0
        correctAnswers = 0
        bestStreak = 0
        currentStreak = 0
        sessionStartTime = Date()
        isQuizComplete = false
        showStreakAnimation = false
        currentDayStreak = nil

        Task {
            do {
                let selectedWords = try await fetchPracticeWords()
                guard !selectedWords.isEmpty else {
                    await MainActor.run {
                        self.loadingState = .error(Loc.Quizzes.notEnoughWordsAvailable(self.preset.itemCount))
                    }
                    return
                }

                await MainActor.run {
                    self.loadingState = .generating
                }

                let inputs = selectedWords.map {
                    AIPronunciationPracticeWordInput(word: $0.quiz_text, language: $0.quiz_language)
                }

                let response: AIPronunciationPracticeResponse = try await aiService.generatePronunciationPractice(for: inputs)
                let practiceItems = buildPracticeItems(from: selectedWords, response: response)

                guard practiceItems.count == self.preset.itemCount else {
                    await MainActor.run {
                        self.loadingState = .error(Loc.Quizzes.quizUnavailable)
                    }
                    return
                }

                await MainActor.run { [practiceItems] in
                    self.practiceItems = practiceItems
                    self.wordSummaries = practiceItems.map {
                        WordSummary(
                            word: $0.word.quiz_text,
                            sentence: $0.sentence
                        )
                    }
                    self.configureQuiz()
                    self.loadingState = .ready
                }
            } catch {
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                }
            }
        }
    }

    private func fetchPracticeWords() async throws -> [any Quizable] {
        let availableItems = quizItemsProvider.getItemsForQuiz(with: preset)
        let candidateWords = availableItems.filter { item in
            item.quiz_itemType == .word && item.quiz_languageCode.isNotEmpty
        }

        guard !candidateWords.isEmpty else { return [] }

        if let selectedLanguage = quizItemsProvider.selectedLanguage {
            let filtered = candidateWords.filter { $0.quiz_languageCode.lowercased() == selectedLanguage.languageCode.lowercased() }
            let words = Array(filtered.shuffled().prefix(preset.itemCount))
            return words.count == preset.itemCount ? words : []
        } else {
            let grouped = Dictionary(grouping: candidateWords, by: { $0.quiz_languageCode.lowercased() })
            if let (_, words) = grouped.first(where: { $0.value.count >= preset.itemCount }) {
                return Array(words.shuffled().prefix(preset.itemCount))
            } else if let maxGroup = grouped.max(by: { $0.value.count < $1.value.count }), maxGroup.value.count >= preset.itemCount {
                return Array(maxGroup.value.shuffled().prefix(preset.itemCount))
            } else {
                return []
            }
        }
    }

    private func buildPracticeItems(from words: [any Quizable], response: AIPronunciationPracticeResponse) -> [PracticeItem] {
        var items: [PracticeItem] = []
        let responseItems = response.items

        for (index, word) in words.enumerated() where index < responseItems.count {
            let responseItem = responseItems[index]

            let item = PracticeItem(
                word: word,
                sentence: responseItem.sentence,
                language: responseItem.language
            )
            items.append(item)
        }

        return items
    }

    private func configureQuiz() {
        guard !practiceItems.isEmpty else { return }

        quizConfig = PronunciationQuizConfig(
            items: practiceItems.enumerated().map { offset, item in
                PronunciationQuizConfig.Item(
                    index: offset,
                    text: item.sentence,
                    language: item.language
                )
            },
            onAnswer: { [weak self] submission in
                self?.handleSubmission(submission)
            },
            onCompletion: { [weak self] submissions in
                self?.handleCompletion(submissions)
            }
        )
    }

    // MARK: - Quiz Handling

    private func handleSubmission(_ submission: PronunciationQuizConfig.SubmissionItem) {
        guard !isQuizComplete else { return }
        let questionIndex = submission.item.index
        guard practiceItems.indices.contains(questionIndex) else { return }
        guard results[questionIndex] == nil else { return }

        let practiceItem = practiceItems[questionIndex]
        results[questionIndex] = submission.isCorrect
        transcripts[questionIndex] = submission.spokenText

        updateSummary(
            at: questionIndex,
            transcript: submission.spokenText,
            isCorrect: submission.isCorrect
        )

        itemsPlayed.append(practiceItem.word)
        accuracyContributionSum += submission.isCorrect ? 1 : 0

        if submission.isCorrect {
            correctAnswers += 1
            score += 5
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            correctItemIds.append(practiceItem.word.quiz_id)
            updateItemScore(practiceItem.word, points: 5)
        } else {
            score -= 2
            currentStreak = 0
            updateItemScore(practiceItem.word, points: -2)
        }
    }

    private func handleCompletion(_ submissions: [PronunciationQuizConfig.SubmissionItem]) {
        guard !isQuizComplete else { return }
        submissions.forEach { submission in
            let index = submission.item.index
            if results[index] == nil {
                handleSubmission(submission)
            }
        }

        isQuizComplete = true
        saveQuizSession()
    }

    private func updateSummary(at index: Int, transcript: String, isCorrect: Bool) {
        guard wordSummaries.indices.contains(index) else { return }
        wordSummaries[index].transcript = transcript
        wordSummaries[index].isCorrect = isCorrect
    }

    private func updateItemScore(_ item: any Quizable, points: Int) {
        if let sharedItem = item as? SharedWord {
            if let userEmail = AuthenticationService.shared.userEmail {
                sharedItem.quiz_updateDifficultyScoreForUser(points, userEmail: userEmail)
            }
        } else {
            item.quiz_updateDifficultyScore(points)
        }
    }

    private func saveQuizSession() {
        guard !isSavingSession else { return }
        isSavingSession = true

        let wasFirstQuizToday = quizAnalyticsService.isFirstQuizToday()
        let duration = Date().timeIntervalSince(sessionStartTime)
        let totalItems = itemsPlayed.count
        let accuracyAverage = totalItems > 0 ? accuracyContributionSum / Double(totalItems) : 0

        quizAnalyticsService.saveQuizSession(
            quizType: Quiz.pronunciationPractice.rawValue,
            score: score,
            correctAnswers: correctAnswers,
            totalItems: totalItems,
            duration: duration,
            accuracy: accuracyAverage,
            itemsPracticed: itemsPlayed,
            correctItemIds: correctItemIds
        )

        if wasFirstQuizToday {
            let newStreak = quizAnalyticsService.calculateCurrentStreak()
            showStreakAnimation = true
            currentDayStreak = newStreak
        }

        isSavingSession = false
    }

    var totalAccuracyContribution: Double {
        accuracyContributionSum
    }

    var totalQuestions: Int {
        practiceItems.count
    }
}


import Core
import CoreUserInterface
import Services
import Shared
import Combine

public final class SpellingQuizViewModel: DefaultPageViewModel {

    enum Input {
        case confirmAnswer
        case dismiss
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published var answerTextField = ""

    @Published private(set) var words: [Word] = []
    @Published private(set) var randomWord: Word?
    @Published private(set) var isCorrectAnswer = true
    @Published private(set) var attemptCount = 0

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []
    private var wordsPlayedCount: Int = 0

    public init(wordsProvider: WordsProviderInterface) {
        self.wordsProvider = wordsProvider
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .confirmAnswer:
            confirmAnswer()
        case .dismiss:
            onOutput?(.finish)
        }
    }

    private func confirmAnswer() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.id == randomWord.id })
        else { return }

        if answerTextField.lowercased().trimmed == randomWord.word.lowercased().trimmed {
            isCorrectAnswer = true
            answerTextField = ""
            words.remove(at: wordIndex)
            attemptCount = 0
            if !words.isEmpty {
                self.randomWord = words.randomElement()
            } else {
                self.randomWord = nil
            }
            HapticManager.shared.triggerNotification(type: .success)
            wordsPlayedCount += 1
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        } else {
            isCorrectAnswer = false
            attemptCount += 1
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.spellingQuizAnswerConfirmed)
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
                self?.randomWord = words.randomElement()
            }
            .store(in: &cancellables)
    }
}

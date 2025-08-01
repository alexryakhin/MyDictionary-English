import Foundation
import Combine

final class ChooseDefinitionQuizViewModel: BaseViewModel {

    enum Input {
        case answerSelected(Int)
        case dismiss
    }

    enum Output {
        case finish
    }

    var onOutput: ((Output) -> Void)?

    @Published private(set) var words: [Word] = []
    @Published private(set) var correctAnswerIndex: Int
    @Published private(set) var isCorrectAnswer = true

    var correctWord: Word {
        words[correctAnswerIndex]
    }

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []
    private var wordsPlayedCount: Int = 0

    init(wordsProvider: WordsProviderInterface) {
        self.wordsProvider = wordsProvider
        self.correctAnswerIndex = Int.random(in: 0...2)
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .answerSelected(let index):
            answerSelected(index)
        case .dismiss:
            onOutput?(.finish)
        }
    }

    private func answerSelected(_ index: Int) {
        if correctWord.id == words[index].id {
            isCorrectAnswer = true
            words.shuffle()
            correctAnswerIndex = Int.random(in: 0...2)
            HapticManager.shared.triggerNotification(type: .success)
            wordsPlayedCount += 1
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        } else {
            isCorrectAnswer = false
            HapticManager.shared.triggerNotification(type: .error)
            AnalyticsService.shared.logEvent(.definitionQuizAnswerSelected)
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.words = $0.shuffled()
            }
            .store(in: &cancellables)
    }
}

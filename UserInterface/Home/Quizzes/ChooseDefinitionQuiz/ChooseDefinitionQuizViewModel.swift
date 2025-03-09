import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared
import Combine

public final class ChooseDefinitionQuizViewModel: DefaultPageViewModel {

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

    public init(wordsProvider: WordsProviderInterface) {
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
        } else {
            isCorrectAnswer = false
            HapticManager.shared.triggerNotification(type: .error)
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)
    }
}

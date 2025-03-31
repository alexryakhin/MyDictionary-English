import SwiftUI
import Combine
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class QuizzesViewModel: DefaultPageViewModel {

    enum Input {
        case selectQuiz(Quiz)
        case deselectQuiz
    }

    @Published private(set) var selectedQuiz: Quiz?
    @Published private(set) var words: [Word] = []

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectQuiz(let quiz):
            Task { @MainActor in
                selectedQuiz = quiz
            }
        case .deselectQuiz:
            selectedQuiz = nil
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
                if words.count < 10 {
                    self?.additionalState = .placeholder(
                        .init(
                            title: "Not enough words",
                            subtitle: "Add at least 10 words to play!"
                        )
                    )
                } else {
                    self?.resetAdditionalState()
                }
            }
            .store(in: &cancellables)
    }
}

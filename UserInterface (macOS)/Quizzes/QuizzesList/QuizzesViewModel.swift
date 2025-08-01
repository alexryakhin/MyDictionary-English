import SwiftUI
import Combine

final class QuizzesViewModel: BaseViewModel {

    enum Input {
        case selectQuiz(Quiz)
        case deselectQuiz
    }

    @Published private(set) var selectedQuiz: Quiz?
    @Published private(set) var words: [CDWord] = []

    private let wordsProvider: WordsProvider
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
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
        wordsProvider.$words
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
                // Words loaded successfully
            }
            .store(in: &cancellables)
    }
}

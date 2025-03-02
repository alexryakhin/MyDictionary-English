import SwiftUI
import Combine

final class QuizzesViewModel: DefaultPageViewModel {
    @Published var words: [Word] = []

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []

    init(wordsProvider: WordsProviderInterface) {
        self.wordsProvider = wordsProvider
        super.init()
        setupBindings()
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)
    }
}

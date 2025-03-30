import SwiftUI
import Combine
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class QuizzesViewModel: DefaultPageViewModel {
    @Published var selectedQuiz: Quiz?
    @Published var words: [Word] = []

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
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

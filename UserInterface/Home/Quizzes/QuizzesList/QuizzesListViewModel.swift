//
//  QuizzesListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

class QuizzesListViewModel: BaseViewModel {

    enum Input {
        case showQuiz(Quiz)
    }

    enum Output {
        case showQuiz(Quiz)
    }

    var onOutput: ((Output) -> Void)?

    @Published var words: [Word] = []

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []

    init(wordsProvider: WordsProviderInterface) {
        self.wordsProvider = wordsProvider
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .showQuiz(let quiz):
            onOutput?(.showQuiz(quiz))
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
            }
            .store(in: &cancellables)
    }
}

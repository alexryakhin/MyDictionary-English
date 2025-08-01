//
//  QuizzesListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine

final class QuizzesListViewModel: BaseViewModel {

    enum Input {
        // No navigation inputs needed
    }

    @Published var words: [CDWord] = []

    private let wordsProvider: WordsProvider
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        // No navigation handling needed
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
            }
            .store(in: &cancellables)
    }
}

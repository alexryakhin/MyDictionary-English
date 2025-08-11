//
//  QuizzesListViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import Combine
import SwiftUI

final class QuizzesListViewModel: BaseViewModel {

    enum Output {
        case showSpellingQuiz(wordCount: Int, hardWordsOnly: Bool)
        case showChooseDefinitionQuiz(wordCount: Int, hardWordsOnly: Bool)
    }

    enum Input {
        // No navigation inputs needed
    }

    var output = PassthroughSubject<Output, Never>()

    @Published var words: [CDWord] = []
    @Published var showingHardWordsOnly = false

    private let wordsProvider: WordsProvider = .shared
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        // No input handling needed
    }
    
    // MARK: - Computed Properties
    
    var filteredWords: [CDWord] {
        if showingHardWordsOnly {
            return words.filter { $0.difficultyLevel == 2 } // needsReview
        }
        return words
    }
    
    var hasHardWords: Bool {
        return words.filter { $0.difficultyLevel == 2 }.count > 10
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                self?.words = words
            }
            .store(in: &cancellables)
    }
}

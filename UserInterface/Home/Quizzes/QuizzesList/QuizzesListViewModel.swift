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

    enum Input {
        // No navigation inputs needed
    }

    @Published var words: [CDWord] = []
    @AppStorage(UDKeys.practiceHardWordsOnly) var showingHardWordsOnly = false

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
    
    // MARK: - Computed Properties
    
    var filteredWords: [CDWord] {
        if showingHardWordsOnly {
            return words.filter { $0.difficultyLevel == 2 } // needsReview
        }
        return words
    }
    
    var hasHardWords: Bool {
        return words.contains { $0.difficultyLevel == 2 }
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

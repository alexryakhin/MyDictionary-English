//
//  SpellingQuizViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI
import Combine

final class SpellingQuizViewModel: BaseViewModel {
    @Published var words: [CDWord] = []

    @Published var randomWord: CDWord?
    @Published var answerTextField = ""
    @Published var isCorrectAnswer = true
    @Published var attemptCount = 0

    private let wordsProvider: WordsProvider
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        super.init()
        setupBindings()
    }

    func confirmAnswer() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.id == randomWord.id })
        else { return }

        if answerTextField.lowercased().trimmed == (randomWord.wordItself?.lowercased().trimmed ?? "") {
            isCorrectAnswer = true
            answerTextField = ""
            words.remove(at: wordIndex)
            attemptCount = 0
            if !words.isEmpty {
                self.randomWord = words.randomElement()
            } else {
                self.randomWord = nil
            }
        } else {
            isCorrectAnswer = false
            attemptCount += 1
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
                self?.randomWord = words.randomElement()
            }
            .store(in: &cancellables)
    }
}

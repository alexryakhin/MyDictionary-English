//
//  SpellingQuizViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI
import Combine
import Core
import Services
import CoreUserInterface__macOS_
import Shared

final class SpellingQuizViewModel: DefaultPageViewModel {
    @Published var words: [Word] = []

    @Published var randomWord: Word?
    @Published var answerTextField = ""
    @Published var isCorrectAnswer = true
    @Published var attemptCount = 0

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
        super.init()
        setupBindings()
    }

    func confirmAnswer() {
        guard let randomWord,
              let wordIndex = words.firstIndex(where: { $0.id == randomWord.id })
        else { return }

        if answerTextField.lowercased().trimmed == randomWord.word.lowercased().trimmed {
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
        wordsProvider.wordsPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
                self?.randomWord = words.randomElement()
            }
            .store(in: &cancellables)
    }
}

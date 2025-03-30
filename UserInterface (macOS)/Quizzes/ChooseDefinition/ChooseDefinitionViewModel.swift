//
//  ChooseDefinitionViewModel.swift
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

final class ChooseDefinitionViewModel: DefaultPageViewModel {
    @Published var words: [Word] = []
    @Published var correctAnswerIndex = Int.random(in: 0...2)
    @Published var isCorrectAnswer = true

    var correctWord: Word {
        words[correctAnswerIndex]
    }

    private let wordsProvider: WordsProviderInterface
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
        super.init()
        setupBindings()
    }

    func answerSelected(_ index: Int) {
        withAnimation {
            if correctWord.id == words[index].id {
                isCorrectAnswer = true
                words.shuffle()
                correctAnswerIndex = Int.random(in: 0...2)
            } else {
                isCorrectAnswer = false
            }
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)
    }
}

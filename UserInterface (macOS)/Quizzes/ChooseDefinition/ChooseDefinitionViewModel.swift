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

    enum Input {
        case selectAnswer(Int)
        case playWord
        case setRandomIndex
    }

    @Published private(set) var words: [Word] = []
    @Published private(set) var correctAnswerIndex = Int.random(in: 0...2)
    @Published private(set) var isCorrectAnswer = true

    private var correctWord: Word {
        words[correctAnswerIndex]
    }

    private let wordsProvider: WordsProviderInterface
    private let ttsPlayer: TTSPlayerInterface
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = DIContainer.shared.resolver.resolve(WordsProviderInterface.self)!
        self.ttsPlayer = DIContainer.shared.resolver.resolve(TTSPlayerInterface.self)!
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectAnswer(let index):
            answerSelected(index)
        case .playWord:
            play(correctWord.word)
        case .setRandomIndex:
            correctAnswerIndex = Int.random(in: 0...2)
        }
    }

    private func answerSelected(_ index: Int) {
        if correctWord.id == words[index].id {
            isCorrectAnswer = true
            words.shuffle()
            correctAnswerIndex = Int.random(in: 0...2)
        } else {
            isCorrectAnswer = false
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.wordsPublisher
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words.shuffled()
                self?.correctAnswerIndex = Int.random(in: 0...2)
            }
            .store(in: &cancellables)
    }

    private func play(_ text: String?) {
        Task {
            if let text {
                do {
                    try await ttsPlayer.play(text)
                } catch {
                    errorReceived(error, displayType: .alert)
                }
            }
        }
    }
}

//
//  ChooseDefinitionViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/21/25.
//

import SwiftUI
import Combine

final class ChooseDefinitionViewModel: BaseViewModel {

    enum Input {
        case selectAnswer(Int)
        case playWord
        case setRandomIndex
    }

    @Published private(set) var words: [CDWord] = []
    @Published private(set) var correctAnswerIndex = Int.random(in: 0...2)
    @Published private(set) var isCorrectAnswer = true

    private var correctWord: CDWord {
        words[correctAnswerIndex]
    }

    private let wordsProvider: WordsProvider
    private let ttsPlayer: TTSPlayer
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        self.ttsPlayer = ServiceManager.shared.ttsPlayer
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectAnswer(let index):
            answerSelected(index)
        case .playWord:
            play(correctWord.wordItself)
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
        wordsProvider.$words
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

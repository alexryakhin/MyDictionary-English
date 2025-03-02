//
//  WordDetailsViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import Combine
import SwiftUI
import Foundation

final class WordDetailsViewModel: DefaultPageViewModel {
    @Binding var word: Word?
    @Published var isShowAddExample = false
    @Published var definitionTextFieldStr = ""
    @Published var exampleTextFieldStr = ""

    private let wordsManager: WordsManagerInterface
    private let speechSynthesizer = SpeechSynthesizer.shared
    private var cancellables: Set<AnyCancellable> = []

    init(
        word: Binding<Word?>,
        wordsManager: WordsManagerInterface
    ) {
        self._word = word
        self.wordsManager = wordsManager
        self.definitionTextFieldStr = word.wrappedValue?.definition ?? ""
        super.init()
        setupBindings()
    }

    func removeExample(_ example: String) {
        do {
            try word?.removeExample(example)
            saveContext()
        } catch {
            errorReceived(error, displayType: .snack)
        }
    }

    func removeExample(atOffsets offsets: IndexSet) {
        do {
            try word?.removeExample(atOffsets: offsets)
            saveContext()
        } catch {
            errorReceived(error, displayType: .snack)
        }
    }

    func saveExample() {
        do {
            try word?.addExample(exampleTextFieldStr)
            saveContext()
            exampleTextFieldStr = ""
            isShowAddExample = false
        } catch {
            errorReceived(error, displayType: .snack)
        }
    }

    func speak(_ text: String?) {
        if let text {
            speechSynthesizer.speak(text)
        }
    }

    func changePartOfSpeech(_ partOfSpeech: String) {
        word?.partOfSpeech = partOfSpeech
        saveContext()
    }

    func deleteCurrentWord() {
        guard let word else { return }
        wordsManager.delete(word: word)
        saveContext()
        self.word = nil
    }

    func toggleFavorite() {
        word?.isFavorite.toggle()
        saveContext()
    }

    private func setupBindings() {
        $definitionTextFieldStr
            .removeDuplicates()
            .debounce(for: 1, scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.word?.definition = text
                self?.saveContext()
            }
            .store(in: &cancellables)
    }

    private func saveContext() {
        do {
            try wordsManager.saveContext()
        } catch {
            errorReceived(error, displayType: .snack)
        }
    }
}

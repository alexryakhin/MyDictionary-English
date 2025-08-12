//
//  QuizzesFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct QuizzesFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared
    @ObservedObject var viewModel: QuizzesListViewModel

    // MARK: - Body

    var body: some View {
        QuizzesListContentView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: QuizzesListViewModel.Output) {
        switch output {
        case .showSpellingQuiz(let wordCount, let hardWordsOnly):
            navigationManager.navigationPath.append(NavigationDestination.spellingQuiz(wordCount: wordCount, hardWordsOnly: hardWordsOnly))
        case .showChooseDefinitionQuiz(let wordCount, let hardWordsOnly):
            navigationManager.navigationPath.append(NavigationDestination.chooseDefinitionQuiz(wordCount: wordCount, hardWordsOnly: hardWordsOnly))
        case .showSharedDictionary(let dictionary):
            navigationManager.navigationPath.append(NavigationDestination.sharedDictionaryWords(dictionary))
        }
    }
}

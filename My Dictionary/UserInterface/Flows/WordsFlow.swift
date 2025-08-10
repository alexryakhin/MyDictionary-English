//
//  WordsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct WordsFlow: View {

    // MARK: - Properties

    @Binding var navigationPath: NavigationPath
    @ObservedObject var viewModel: WordListViewModel

    // MARK: - Body

    var body: some View {
        WordListView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: WordListViewModel.Output) {
        switch output {
        case .showWordDetails(let word):
            let config = WordDetailsContentView.Config(word: word, dictionary: nil)
            navigationPath.append(NavigationDestination.wordDetails(config))
        case .showAddWord:
            navigationPath.append(NavigationDestination.addWord)
        case .showSharedDictionaries:
            navigationPath.append(NavigationDestination.sharedDictionariesList)
        case .showAddSharedDictionary:
            navigationPath.append(NavigationDestination.addSharedDictionary)
        case .showAddExistingWordToShared(let word):
            navigationPath.append(NavigationDestination.addExistingWordToShared(word))
        }
    }
}

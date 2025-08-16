//
//  WordsFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct WordsFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared
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
            navigationManager.navigationPath.append(NavigationDestination.wordDetails(word))
        case .showAddWord:
            navigationManager.navigationPath.append(NavigationDestination.addWord)
        case .showSharedDictionaries:
            navigationManager.navigationPath.append(NavigationDestination.sharedDictionariesList)
        case .showAddExistingWordToShared(let word):
            navigationManager.navigationPath.append(NavigationDestination.addExistingWordToShared(word))
        }
    }
}

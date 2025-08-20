//
//  VocabularyFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct VocabularyFlow: View {

    // MARK: - Properties

    @StateObject private var navigationManager: NavigationManager = .shared

    @ObservedObject var wordListViewModel: WordListViewModel
    @ObservedObject var idiomListViewModel: IdiomListViewModel

    // MARK: - Body

    var body: some View {
        VocabularyListView(
            wordListViewModel: wordListViewModel,
            idiomListViewModel: idiomListViewModel
        )
        .onReceive(wordListViewModel.output) { output in
            handleWordsOutput(output)
        }
        .onReceive(idiomListViewModel.output) { output in
            handleIdiomsOutput(output)
        }
    }

    // MARK: - Private Methods

    private func handleWordsOutput(_ output: WordListViewModel.Output) {
        switch output {
        case .showWordDetails(let word):
            navigationManager.navigationPath.append(NavigationDestination.wordDetails(word))
        case .showAddWord(let inputWord):
            navigationManager.navigationPath.append(NavigationDestination.addWord(inputWord))
        case .showSharedDictionaries:
            navigationManager.navigationPath.append(NavigationDestination.sharedDictionariesList)
        case .showAddExistingWordToShared(let word):
            navigationManager.navigationPath.append(NavigationDestination.addExistingWordToShared(word))
        }
    }
    
    private func handleIdiomsOutput(_ output: IdiomListViewModel.Output) {
        switch output {
        case .showIdiomDetails(let idiom):
            navigationManager.navigationPath.append(NavigationDestination.idiomDetails(idiom))
        case .showAddIdiom(let input):
            navigationManager.navigationPath.append(NavigationDestination.addIdiom(input))
        }
    }
}

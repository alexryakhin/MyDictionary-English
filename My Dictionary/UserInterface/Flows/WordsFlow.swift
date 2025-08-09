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
        WordListContentView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: WordListViewModel.Output) {
        switch output {
        case .showWordDetails(let word):
            navigationPath.append(word)
        case .showAddWord:
            navigationPath.append("add_word")
        case .showSharedDictionary(let dictionary):
            navigationPath.append(dictionary)
        case .showAddSharedDictionary:
            navigationPath.append("add_shared_dictionary")
        case .showAddExistingWordToShared(let word):
            navigationPath.append("add_existing_word_\(word.id?.uuidString ?? "")")
        }
    }
}

//
//  QuizzesFlow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI

struct QuizzesFlow: View {

    // MARK: - Properties

    @Binding var navigationPath: NavigationPath
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
            navigationPath.append("spelling_quiz_\(wordCount)_\(hardWordsOnly)")
        case .showChooseDefinitionQuiz(let wordCount, let hardWordsOnly):
            navigationPath.append("choose_definition_quiz_\(wordCount)_\(hardWordsOnly)")
        }
    }
}

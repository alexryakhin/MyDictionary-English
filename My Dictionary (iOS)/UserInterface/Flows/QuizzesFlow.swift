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
        QuizzesListView(viewModel: viewModel)
            .onReceive(viewModel.output) { output in
                handleOutput(output)
            }
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: QuizzesListViewModel.Output) {
        switch output {
        case .showSpellingQuiz(let preset):
            navigationManager.navigationPath.append(NavigationDestination.spellingQuiz(preset))
        case .showChooseDefinitionQuiz(let preset):
            navigationManager.navigationPath.append(NavigationDestination.chooseDefinitionQuiz(preset))
        case .showSentenceWritingQuiz(let preset):
            navigationManager.navigationPath.append(NavigationDestination.sentenceWritingQuiz(preset))
        case .showContextMultipleChoiceQuiz(let preset):
            navigationManager.navigationPath.append(NavigationDestination.contextMultipleChoiceQuiz(preset))
        case .showFillInTheBlankQuiz(let preset):
            navigationManager.navigationPath.append(NavigationDestination.fillInTheBlankQuiz(preset))
        case .showStoryLab(let config):
            navigationManager.navigationPath.append(NavigationDestination.storyLab(config))
        case .showSharedDictionary(let dictionary):
            navigationManager.navigationPath.append(NavigationDestination.sharedDictionaryWords(dictionary))
        }
    }
}

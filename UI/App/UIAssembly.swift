//
//  UIAssembly.swift
//  MyDictionaryApp
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import Swinject
import SwinjectAutoregistration
import SwiftUI

final class UIAssembly: Assembly, Identifiable {

    var id: String = "UIAssembly"

    func assemble(container: Container) {
        container.register(MainTabView.self) { _ in
            MainTabView()
        }

        container.register(OnboardingView.self) { _ in
            OnboardingView()
        }

        container.register(WordsListViewController.self) { resolver in
            let viewModel = WordsListViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self,
                wordsManager: resolver ~> WordsManagerInterface.self
            )
            return WordsListView(viewModel: viewModel)
        }

        container.register(AddWordView.self) { resolver, inputWord in
            let viewModel = AddWordViewModel(
                inputWord: inputWord,
                wordnikApiService: resolver ~> WordnikApiServiceInterface.self,
                wordsManager: resolver ~> WordsManagerInterface.self
            )
            return AddWordView(viewModel: viewModel)
        }

        container.register(WordDetailsView.self) { resolver, word in
            let viewModel = WordDetailsViewModel(
                word: word,
                wordsManager: resolver ~> WordsManagerInterface.self
            )
            return WordDetailsView(viewModel: viewModel)
        }

        container.register(IdiomsListView.self) { resolver in
            let viewModel = IdiomsViewModel(
                idiomsProvider: resolver ~> IdiomsProviderInterface.self,
                idiomsManager: resolver ~> IdiomsManagerInterface.self
            )
            return IdiomsListView(viewModel: viewModel)
        }

        container.register(AddIdiomView.self) { resolver, inputText in
            let viewModel = AddIdiomViewModel(
                inputText: inputText,
                idiomsManager: resolver ~> IdiomsManagerInterface.self
            )
            return AddIdiomView(viewModel: viewModel)
        }

        container.register(IdiomDetailsView.self) { resolver, idiom in
            let viewModel = IdiomDetailsViewModel(
                idiom: idiom,
                idiomsManager: resolver ~> IdiomsManagerInterface.self
            )
            return IdiomDetailsView(viewModel: viewModel)
        }

        container.register(QuizzesView.self) { resolver in
            let viewModel = QuizzesViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            return QuizzesView(viewModel: viewModel)
        }

        container.register(SpellingQuizView.self) { resolver in
            let viewModel = SpellingQuizViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            return SpellingQuizView(viewModel: viewModel)
        }

        container.register(ChooseDefinitionView.self) { resolver in
            let viewModel = ChooseDefinitionViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            return ChooseDefinitionView(viewModel: viewModel)
        }

        container.register(SettingsView.self) { resolver in
            let viewModel = SettingsViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            return SettingsView(viewModel: viewModel)
        }
    }
}

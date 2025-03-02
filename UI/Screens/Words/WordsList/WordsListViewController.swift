//
//  MainController.swift
//  My Dictionary (iOS)
//
//  Created by Aleksandr Riakhin on 3/2/25.
//

import UIKit
import Combine

final class WordsListViewController: PageViewController<WordsListView> {

    enum Event {
        case openWordDetails(config: RecipeDetailsPageViewModel.Config)
    }
    var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: MainPageViewModel

    // MARK: - Initialization

    init(viewModel: MainPageViewModel) {
        self.viewModel = viewModel
        super.init(rootView: MainPageView(viewModel: viewModel))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()
        tabBarItem = TabBarItem.main.item
        setupBindings()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onEvent = { [weak self] event in
            switch event {
            case .openRecipeDetails(let config):
                self?.onEvent?(.openRecipeDetails(config: config))
            case .openSearchScreen:
                self?.onEvent?(.openSearchScreen)
            }
        }
    }
}

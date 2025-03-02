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
        case showAddWord
        case openWordDetails(UUID)
    }

    var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: WordsListViewModel

    // MARK: - Initialization

    init(viewModel: WordsListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WordsListView(viewModel: viewModel))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()
        tabBarItem = TabBarItem.words.item
        setupBindings()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
            case .showAddWord:
                self?.onEvent?(.showAddWord)
            case .showWordDetails(let uuid):
                self?.onEvent?(.openWordDetails(uuid))
            }
        }
    }
}

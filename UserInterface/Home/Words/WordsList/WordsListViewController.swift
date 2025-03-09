//
//  ViewController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class WordsListViewController: PageViewController<WordsListContentView> {

    public enum Event {
        case showAddWord(searchText: String)
        case openWordDetails(word: Word)
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: WordsListViewModel

    // MARK: - Initialization

    public init(viewModel: WordsListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WordsListContentView(viewModel: viewModel))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
        tabBarItem = TabBarItem.words.item
        navigationItem.title = TabBarItem.words.title
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
            case .showAddWord(let searchText):
                self?.onEvent?(.showAddWord(searchText: searchText))
            case .showWordDetails(let word):
                self?.onEvent?(.openWordDetails(word: word))
            }
        }
    }
}

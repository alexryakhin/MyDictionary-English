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
        case showAddWord
        case openWordDetails(UUID)
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
        tabBarItem = TabBarItem.words.item
        setupBindings()
    }

    public override func setupNavigationBar(animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        resetNavBarAppearance()
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

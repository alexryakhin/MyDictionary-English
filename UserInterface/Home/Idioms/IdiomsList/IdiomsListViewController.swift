//
//  IdiomsListViewController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class IdiomsListViewController: PageViewController<IdiomsListContentView> {

    public enum Event {
        case showAddIdiom(searchText: String)
        case showIdiomDetails(idiom: Idiom)
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: IdiomsListViewModel

    // MARK: - Initialization

    public init(viewModel: IdiomsListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: IdiomsListContentView(viewModel: viewModel))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        tabBarItem = TabBarItem.idioms.item
        setupBindings()
    }

    public override func setupNavigationBar(animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
            case .showAddIdiom(let searchText):
                self?.onEvent?(.showAddIdiom(searchText: searchText))
            case .showIdiomDetails(let idiom):
                self?.onEvent?(.showIdiomDetails(idiom: idiom))
            }
        }
    }
}

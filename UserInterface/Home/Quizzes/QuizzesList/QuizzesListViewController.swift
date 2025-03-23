//
//  QuizzesListViewController.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class QuizzesListViewController: PageViewController<QuizzesListContentView>, NavigationBarVisible {

    public enum Event {
        case showQuiz(Quiz)
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: QuizzesListViewModel

    // MARK: - Initialization

    public init(viewModel: QuizzesListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: QuizzesListContentView(viewModel: viewModel))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
        tabBarItem = TabBarItem.quizzes.item
        navigationItem.title = TabBarItem.quizzes.title
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
            case .showQuiz(let quiz):
                self?.onEvent?(.showQuiz(quiz))
            }
        }
    }
}

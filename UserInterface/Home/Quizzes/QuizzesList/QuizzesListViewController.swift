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

public final class QuizzesListViewController: PageViewController<QuizzesListContentView> {

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
        tabBarItem = TabBarItem.quizzes.item
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
            case .showQuiz(let quiz):
                self?.onEvent?(.showQuiz(quiz))
            }
        }
    }
}

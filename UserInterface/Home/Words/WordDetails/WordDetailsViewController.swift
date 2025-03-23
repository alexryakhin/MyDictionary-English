import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class WordDetailsViewController: PageViewController<WordDetailsContentView>, NavigationBarVisible {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: WordDetailsViewModel

    // MARK: - Initialization

    public init(viewModel: WordDetailsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WordDetailsContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
        navigationItem.title = viewModel.word.word
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
            case .finish: self?.onEvent?(.finish)
            }
        }
    }
}

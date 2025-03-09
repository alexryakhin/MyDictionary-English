import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class SpellingQuizViewController: PageViewController<SpellingQuizContentView> {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: SpellingQuizViewModel

    // MARK: - Initialization

    public init(viewModel: SpellingQuizViewModel) {
        self.viewModel = viewModel
        super.init(rootView: SpellingQuizContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
        title = "Spelling"
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

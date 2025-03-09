import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class IdiomDetailsViewController: PageViewController<IdiomDetailsContentView> {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: IdiomDetailsViewModel

    // MARK: - Initialization

    public init(viewModel: IdiomDetailsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: IdiomDetailsContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
        navigationItem.title = "Details"
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

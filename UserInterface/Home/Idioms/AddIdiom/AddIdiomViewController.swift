import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class AddIdiomViewController: PageViewController<AddIdiomContentView>, NavigationBarVisible {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: AddIdiomViewModel

    // MARK: - Initialization

    public init(viewModel: AddIdiomViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AddIdiomContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
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

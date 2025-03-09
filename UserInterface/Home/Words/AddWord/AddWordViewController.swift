import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class AddWordViewController: PageViewController<AddWordContentView> {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: AddWordViewModel

    // MARK: - Initialization

    public init(viewModel: AddWordViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AddWordContentView(viewModel: viewModel))
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

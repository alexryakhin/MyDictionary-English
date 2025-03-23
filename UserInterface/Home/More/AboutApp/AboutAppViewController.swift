import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class AboutAppViewController: PageViewController<AboutAppContentView>, NavigationBarVisible {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: AboutAppViewModel

    // MARK: - Initialization

    public init(viewModel: AboutAppViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AboutAppContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
        navigationItem.title = NSLocalizedString("About app", comment: .empty)
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
                // handle output
            }
        }
    }
}

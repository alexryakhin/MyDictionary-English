import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class MoreViewController: PageViewController<MoreContentView> {

    public enum Event {
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: MoreViewModel

    // MARK: - Initialization

    public init(viewModel: MoreViewModel) {
        self.viewModel = viewModel
        super.init(rootView: MoreContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        tabBarItem = TabBarItem.more.item
        setupBindings()
    }

    public override func setupNavigationBar(animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
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

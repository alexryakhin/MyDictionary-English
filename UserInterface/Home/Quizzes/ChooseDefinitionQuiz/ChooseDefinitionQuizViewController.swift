import UIKit
import SwiftUI
import CoreUserInterface
import Core

public final class ChooseDefinitionQuizViewController: PageViewController<ChooseDefinitionQuizContentView> {

    public enum Event {
        case finish
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Private properties

    private let viewModel: ChooseDefinitionQuizViewModel

    // MARK: - Initialization

    public init(viewModel: ChooseDefinitionQuizViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ChooseDefinitionQuizContentView(viewModel: viewModel))
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func setup() {
        super.setup()
        setupBindings()
    }

    public override func setupNavigationBar(animated: Bool) {
        navigationController?.navigationBar.prefersLargeTitles = true
        title = "Choose Definition"
    }

    // MARK: - Private Methods

    private func setupBindings() {
        viewModel.onOutput = { [weak self] output in
            switch output {
            case .finish:
                self?.onEvent?(.finish)
            }
        }
    }
}

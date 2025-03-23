import Core
import CoreUserInterface
import Services
import Shared
import Combine
import SwiftUI

public final class AboutAppViewModel: DefaultPageViewModel {

    enum Input {
        // Input actions from the view
    }

    enum Output {
        // Output actions to pass to the view controller
    }

    var onOutput: ((Output) -> Void)?

    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(arg: Int) {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
            // Handle input actions
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Services and Published properties subscriptions
    }
}

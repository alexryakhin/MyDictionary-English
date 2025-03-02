import Combine
import Swinject
import SwinjectAutoregistration

final class DebugCoordinator: Coordinator {

    enum Event {
        case finish
    }
    var onEvent: ((Event) -> Void)?

    // MARK: - Properties

    lazy var debugNavigationController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private let persistent: Persistent = resolver ~> Persistent.self
    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
        innerRouter = Router(rootController: debugNavigationController)
    }

    override func start() {
        presentDebugController()
    }

    // MARK: - Private Methods

    private func presentDebugController() {
        let debugController = resolver ~> DebugController.self

        debugController.onEvent = { [weak self] event in
            switch event {
            case .finish:
                self?.onEvent?(.finish)
            }
        }

        debugNavigationController.addChild(debugController)
        router.present(debugNavigationController, modalPresentationStyle: .fullScreen, animated: true)
    }
}

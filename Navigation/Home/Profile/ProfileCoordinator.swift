import Combine
import Swinject
import SwinjectAutoregistration

final class ProfileCoordinator: Coordinator {

    enum Event {
        case finish
    }
    var onEvent: ((Event) -> Void)?

    // MARK: - Properties

    lazy var profileNavigationController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private let persistent: Persistent = resolver ~> Persistent.self
    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
        innerRouter = Router(rootController: profileNavigationController)
    }

    override func start() {
        profileSearchController()
    }

    // MARK: - Private Methods

    private func profileSearchController() {
        let profileController = resolver ~> ProfileController.self

        profileController.onEvent = { [weak self] event in
            switch event {
            case .finish:
                break
            }
        }

        profileNavigationController.addChild(profileController)
    }
}

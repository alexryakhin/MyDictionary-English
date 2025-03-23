import Swinject
import SwinjectAutoregistration
import UserInterface
import Core
import CoreUserInterface
import CoreNavigation
import Services
import UIKit

final class MoreCoordinator: Coordinator {

    enum Event {
        case finish
    }

    // MARK: - Public Properties

    var onEvent: ((Event) -> Void)?
    lazy var navController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
    }

    override func start() {
        showMainController()
    }

    // MARK: - Private Methods

    private func showMainController() {
        let controller = resolver ~> MoreViewController.self

        controller.onEvent = { [weak self] event in
            switch event {
            case .showAboutApp:
                self?.showAboutApp()
            @unknown default:
                fatalError()
            }
        }

        navController.addChild(controller)
    }

    private func showAboutApp() {
        let controller = resolver ~> AboutAppViewController.self
        router.push(controller)
    }
}

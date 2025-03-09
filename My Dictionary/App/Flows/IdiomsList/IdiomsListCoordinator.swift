import Swinject
import SwinjectAutoregistration
import UserInterface
import Core
import CoreUserInterface
import CoreNavigation
import Services
import UIKit

final class IdiomsListCoordinator: Coordinator {

    // MARK: - Public Properties

    lazy var navController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
        innerRouter = Router(rootController: navController)
    }

    override func start() {
        showMainController()
    }

    // MARK: - Private Methods

    private func showMainController() {
        let controller = resolver ~> IdiomsListViewController.self
        controller.onEvent = { [weak self] event in
            switch event {
            case .showIdiomDetails(let idiom):
                self?.showIdiomDetails(with: idiom)
            case .showAddIdiom(let searchText):
                self?.showAddIdiom(searchText: searchText)
            @unknown default:
                fatalError("Unhandled event")
            }
        }
        navController.addChild(controller)
    }

    private func showIdiomDetails(with idiom: Idiom) {
        let controller = resolver ~> (IdiomDetailsViewController.self, idiom)

        controller.onEvent = { [weak self] event in
            switch event {
            case .finish:
                self?.innerRouter.popToRootModule(animated: true)
            @unknown default:
                fatalError("Unhandled event")
            }
        }

        innerRouter.push(controller)
    }

    public func showAddIdiom(searchText: String) {
        let controller = resolver.resolve(AddIdiomViewController.self, argument: searchText)!
        controller.onEvent = { [weak controller] event in
            switch event {
            case .finish:
                controller?.dismiss(animated: true)
            @unknown default:
                fatalError("Unhandled event")
            }
        }
        router.present(controller)
    }
}

import Combine
import Swinject
import SwinjectAutoregistration
import CoreNavigation
import CoreUserInterface
import UIKit
import UserInterface
import Core

final class WordsListCoordinator: Coordinator {

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
        let controller = resolver ~> WordsListViewController.self
        controller.onEvent = { [weak self] event in
            switch event {
            case .openWordDetails(let word):
                self?.showWordDetails(with: word)
            case .showAddWord:
                break
            @unknown default:
                fatalError("Unhandled event")
            }
        }
        navController.addChild(controller)
    }

    private func showWordDetails(with word: Word) {
        let controller = resolver ~> (WordDetailsViewController.self, word)

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
}

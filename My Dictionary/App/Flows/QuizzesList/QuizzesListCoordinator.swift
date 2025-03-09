import Swinject
import SwinjectAutoregistration
import UserInterface
import Core
import CoreUserInterface
import CoreNavigation
import Services

final class QuizzesListCoordinator: Coordinator {

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
        let controller = resolver ~> QuizzesListViewController.self

        controller.onEvent = { [weak self] event in
            switch event {
            case .showQuiz(let quiz):
                switch quiz {
                case .spelling:
                    self?.showSpellingQuiz()
                case .chooseDefinitions:
                    self?.showChooseDefinitionsQuiz()
                @unknown default:
                    fatalError("Unsupported quiz type")
                }
            @unknown default:
                fatalError("Unsupported event")
            }
        }

        navController.addChild(controller)
    }

    private func showSpellingQuiz() {
        let controller = resolver ~> SpellingQuizViewController.self

        controller.onEvent = { [weak self] event in
            switch event {
            case .finish:
                self?.innerRouter.popToRootModule(animated: true)
            @unknown default:
                fatalError("Unsupported event")
            }
        }

        innerRouter.push(controller)
    }

    private func showChooseDefinitionsQuiz() {
        let controller = resolver ~> ChooseDefinitionQuizViewController.self

        controller.onEvent = { [weak self] event in
            switch event {
            case .finish:
                self?.innerRouter.popToRootModule(animated: true)
            @unknown default:
                fatalError("Unsupported event")
            }
        }

        innerRouter.push(controller)
    }
}

import Swinject
import SwinjectAutoregistration
import CoreUserInterface
import CoreNavigation
import Core
import UserInterface
import Services
import Combine

final class HomeCoordinator: Coordinator {

    required init(router: RouterInterface) {
        super.init(router: router)
    }

    override func start() {
        showTabController()
    }

    private func showTabController() {
        guard topController(ofType: TabController.self) == nil else { return }

        let wordsListNavigationController = assignWordsListCoordinator()

        let controller = resolver ~> TabController.self

        controller.controllers = [
            wordsListNavigationController,
        ]

        router.setRootModule(controller)
    }

    private func assignWordsListCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: WordsListAssembly())

        // WordsList flow coordinator
        guard let wordsListCoordinator = child(ofType: WordsListCoordinator.self)
                ?? resolver.resolve(WordsListCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate WordsListCoordinator") }
        wordsListCoordinator.start()

        let wordsListNavigationController = wordsListCoordinator.navController

        if !contains(child: WordsListCoordinator.self) {
            addDependency(wordsListCoordinator)
        }

        return wordsListNavigationController
    }
}

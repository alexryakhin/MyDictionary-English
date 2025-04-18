import Swinject
import SwinjectAutoregistration
import UserInterface
import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared

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
        let idiomsListNavigationController = assignIdiomsListCoordinator()
        let quizzesListNavigationController = assignQuizzesListCoordinator()
        let moreNavigationController = assignMoreCoordinator()

        let controller = resolver ~> TabController.self

        controller.controllers = [
            wordsListNavigationController,
            idiomsListNavigationController,
            quizzesListNavigationController,
            moreNavigationController
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

    private func assignIdiomsListCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: IdiomsListAssembly())

        // IdiomsList flow coordinator
        guard let idiomsListCoordinator = child(ofType: IdiomsListCoordinator.self)
                ?? resolver.resolve(IdiomsListCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate IdiomsListCoordinator") }
        idiomsListCoordinator.start()

        let idiomsListNavigationController = idiomsListCoordinator.navController

        if !contains(child: IdiomsListCoordinator.self) {
            addDependency(idiomsListCoordinator)
        }

        return idiomsListNavigationController
    }

    private func assignQuizzesListCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: QuizzesListAssembly())

        // QuizzesList flow coordinator
        guard let quizzesListCoordinator = child(ofType: QuizzesListCoordinator.self)
                ?? resolver.resolve(QuizzesListCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate QuizzesListCoordinator") }
        quizzesListCoordinator.start()

        let quizzesListNavigationController = quizzesListCoordinator.navController

        if !contains(child: QuizzesListCoordinator.self) {
            addDependency(quizzesListCoordinator)
        }

        return quizzesListNavigationController
    }

    private func assignMoreCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: MoreAssembly())

        // QuizzesList flow coordinator
        guard let moreCoordinator = child(ofType: MoreCoordinator.self)
                ?? resolver.resolve(MoreCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate MoreCoordinator") }
        moreCoordinator.start()

        let moreNavigationController = moreCoordinator.navController

        if !contains(child: MoreCoordinator.self) {
            addDependency(moreCoordinator)
        }

        return moreNavigationController
    }
}

import Swinject
import SwinjectAutoregistration
import CoreNavigation
import UserInterface
import Services

final class QuizzesListAssembly: Assembly, Identifiable {

    var id: String = "QuizzesListAssembly"

    func assemble(container: Container) {
        container.autoregister(QuizzesListCoordinator.self, argument: RouterInterface.self, initializer: QuizzesListCoordinator.init)

        container.register(QuizzesListViewController.self) { resolver in
            let viewModel = QuizzesListViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            let controller = QuizzesListViewController(viewModel: viewModel)
            return controller
        }
    }
}

import Swinject
import SwinjectAutoregistration
import CoreNavigation
import UserInterface
import Services

final class WordsListAssembly: Assembly, Identifiable {

    var id: String = "WordsListAssembly"

    func assemble(container: Container) {
        container.autoregister(WordsListCoordinator.self, argument: RouterInterface.self, initializer: WordsListCoordinator.init)

        container.register(WordsListViewController.self) { resolver in
            let viewModel = WordsListViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self,
                wordsManager: resolver ~> WordsManagerInterface.self
            )
            let controller = WordsListViewController(viewModel: viewModel)
            return controller
        }
    }
}

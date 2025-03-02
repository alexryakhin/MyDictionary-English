import Swinject
import SwinjectAutoregistration

final class WordsAssembly: Assembly, Identifiable {

    var id: String = "WordsAssembly"

    func assemble(container: Container) {
        container.autoregister(
            WordsCoordinator.self,
            argument: RouterInterface.self,
            initializer: WordsCoordinator.init
        )

        container.register(WordsListViewController.self) { resolver in
            let viewModel = WordsListViewModel(
                spoonacularNetworkService: resolver ~> SpoonacularNetworkServiceInterface.self
            )
            let controller = WordsListViewController(viewModel: viewModel)
            return controller
        }
    }
}

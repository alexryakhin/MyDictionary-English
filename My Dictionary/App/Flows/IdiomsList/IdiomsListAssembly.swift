import Swinject
import SwinjectAutoregistration
import CoreNavigation
import UserInterface
import Services

final class IdiomsListAssembly: Assembly, Identifiable {

    var id: String = "IdiomsListAssembly"

    func assemble(container: Container) {
        container.autoregister(IdiomsListCoordinator.self, argument: RouterInterface.self, initializer: IdiomsListCoordinator.init)

        container.register(IdiomsListViewController.self) { resolver in
            let viewModel = IdiomsListViewModel(
                idiomsProvider: resolver ~> IdiomsProviderInterface.self
            )
            let controller = IdiomsListViewController(viewModel: viewModel)
            return controller
        }

        container.register(IdiomDetailsViewController.self) { resolver, idiom in
            let viewModel = IdiomDetailsViewModel(
                idiom: idiom,
                idiomDetailsManager: resolver.resolve(IdiomDetailsManagerInterface.self, argument: idiom.id)!,
                ttsPlayer: resolver ~> TTSPlayerInterface.self
            )
            let controller = IdiomDetailsViewController(viewModel: viewModel)
            return controller
        }

        container.register(AddIdiomViewController.self) { resolver, searchIdiom in
            let viewModel = AddIdiomViewModel(
                inputIdiom: searchIdiom,
                addIdiomManager: resolver ~> AddIdiomManagerInterface.self
            )
            let controller = AddIdiomViewController(viewModel: viewModel)
            return controller
        }
    }
}

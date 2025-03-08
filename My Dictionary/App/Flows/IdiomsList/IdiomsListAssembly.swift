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
                idiomsProvider: resolver ~> IdiomsProviderInterface.self,
                idiomsManager: resolver ~> IdiomsManagerInterface.self
            )
            let controller = IdiomsListViewController(viewModel: viewModel)
            return controller
        }
    }
}

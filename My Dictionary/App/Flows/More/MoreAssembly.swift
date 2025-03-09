import Swinject
import SwinjectAutoregistration
import UserInterface
import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared

final class MoreAssembly: Assembly, Identifiable {

    var id: String { "MoreAssembly" }

    func assemble(container: Container) {
        container.autoregister(MoreCoordinator.self, argument: RouterInterface.self, initializer: MoreCoordinator.init)

        container.register(MoreViewController.self) { resolver in
            let viewModel = MoreViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self,
                csvManager: resolver ~> CSVManagerInterface.self
            )
            let controller = MoreViewController(viewModel: viewModel)
            return controller
        }
    }

    func loaded(resolver: Resolver) {
        logInfo("More Assembly is loaded")
    }
}

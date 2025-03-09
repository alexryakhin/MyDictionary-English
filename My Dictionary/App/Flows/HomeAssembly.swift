import Swinject
import SwinjectAutoregistration
import UserInterface
import Core
import CoreUserInterface
import CoreNavigation
import Services
import Shared

final class HomeAssembly: Assembly, Identifiable {

    var id: String { "HomeAssembly" }

    func assemble(container: Container) {
        container.autoregister(TabController.self, initializer: TabController.init)

        container.autoregister(HomeCoordinator.self, argument: RouterInterface.self, initializer: HomeCoordinator.init)
    }

    func loaded(resolver: Resolver) {
        logInfo("Home Assembly is loaded")
    }
}

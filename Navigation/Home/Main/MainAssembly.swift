import Swinject
import SwinjectAutoregistration

final class MainAssembly: Assembly, Identifiable {
    
    var id: String = "MainAssembly"

    func assemble(container: Container) {
        container.autoregister(MainCoordinator.self, argument: RouterInterface.self, initializer: MainCoordinator.init)

        container.register(MainController.self) { resolver in
            let viewModel = MainPageViewModel(
                spoonacularNetworkService: resolver ~> SpoonacularNetworkServiceInterface.self
            )
            let controller = MainController(viewModel: viewModel)
            return controller
        }
    }
}

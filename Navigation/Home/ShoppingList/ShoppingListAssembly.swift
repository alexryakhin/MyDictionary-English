import Swinject
import SwinjectAutoregistration

final class ShoppingListAssembly: Assembly, Identifiable {

    var id: String = "ShoppingListAssembly"

    func assemble(container: Container) {
        container.autoregister(ShoppingListCoordinator.self, argument: RouterInterface.self, initializer: ShoppingListCoordinator.init)

        container.register(ShoppingListController.self) { resolver in
            let viewModel = ShoppingListPageViewModel(
                spoonacularNetworkService: resolver ~> SpoonacularNetworkServiceInterface.self
            )
            let controller = ShoppingListController(viewModel: viewModel)
            return controller
        }
    }
}

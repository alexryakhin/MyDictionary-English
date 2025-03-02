import Swinject
import SwinjectAutoregistration

final class DebugAssembly: Assembly, Identifiable {

    var id: String = "DebugAssembly"

    func assemble(container: Container) {
        container.autoregister(DebugCoordinator.self, argument: RouterInterface.self, initializer: DebugCoordinator.init)

        container.register(DebugController.self) { resolver in
            let viewModel = DebugPageViewModel(featureToggleService: resolver ~> FeatureToggleServiceInterface.self)
            let controller = DebugController(viewModel: viewModel)
            return controller
        }
    }
}

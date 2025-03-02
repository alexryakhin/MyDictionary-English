import Swinject
import SwinjectAutoregistration

final class ProfileAssembly: Assembly, Identifiable {

    var id: String = "ProfileAssembly"

    func assemble(container: Container) {
        container.autoregister(ProfileCoordinator.self, argument: RouterInterface.self, initializer: ProfileCoordinator.init)

        container.register(ProfileController.self) { resolver in
            let viewModel = ProfilePageViewModel(arg: 0)
            let controller = ProfileController(viewModel: viewModel)
            return controller
        }
    }
}

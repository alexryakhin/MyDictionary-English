import Swinject
import SwinjectAutoregistration
import CoreNavigation
import UserInterface
import Services

final class QuizzesListAssembly: Assembly, Identifiable {

    var id: String = "QuizzesListAssembly"

    func assemble(container: Container) {
        container.autoregister(QuizzesListCoordinator.self, argument: RouterInterface.self, initializer: QuizzesListCoordinator.init)

        container.register(QuizzesListViewController.self) { resolver in
            let viewModel = QuizzesListViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            let controller = QuizzesListViewController(viewModel: viewModel)
            return controller
        }

        container.register(SpellingQuizViewController.self) { resolver in
            let viewModel = SpellingQuizViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            let controller = SpellingQuizViewController(viewModel: viewModel)
            return controller
        }

        container.register(ChooseDefinitionQuizViewController.self) { resolver in
            let viewModel = ChooseDefinitionQuizViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            let controller = ChooseDefinitionQuizViewController(viewModel: viewModel)
            return controller
        }
    }
}

import Swinject
import SwinjectAutoregistration
import CoreNavigation
import UserInterface
import Services

final class WordsListAssembly: Assembly, Identifiable {

    var id: String = "WordsListAssembly"

    func assemble(container: Container) {
        container.autoregister(WordsListCoordinator.self, argument: RouterInterface.self, initializer: WordsListCoordinator.init)

        container.register(WordsListViewController.self) { resolver in
            let viewModel = WordsListViewModel(
                wordsProvider: resolver ~> WordsProviderInterface.self
            )
            let controller = WordsListViewController(viewModel: viewModel)
            return controller
        }

        container.register(WordDetailsViewController.self) { resolver, word in
            let viewModel = WordDetailsViewModel(
                word: word,
                wordDetailsManager: resolver.resolve(WordDetailsManagerInterface.self, argument: word.id)!,
                speechSynthesizer: resolver ~> SpeechSynthesizerInterface.self
            )
            let controller = WordDetailsViewController(viewModel: viewModel)
            return controller
        }
    }
}

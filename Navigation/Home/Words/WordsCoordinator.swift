import Combine
import Swinject
import SwinjectAutoregistration
import UIKit

final class WordsCoordinator: Coordinator {

    // MARK: - Properties

    lazy var wordsNavigationController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private let persistent: Persistent = resolver ~> Persistent.self
    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
        innerRouter = Router(rootController: wordsNavigationController)
    }

    override func start() {
        showWordsListController()
    }

    // MARK: - Private Methods

    private func showWordsListController() {
        let wordsController = resolver ~> WordsListViewController.self

        wordsController.onEvent = { [weak self] event in
            switch event {
            case .openWordDetails(let uuid):
                break
            case .showAddWord:
                break
            }
        }

        wordsNavigationController.addChild(wordsController)
    }

//    private func openRecipeDetails(with config: RecipeDetailsPageViewModel.Config) {
//        let recipeDetailsController = resolver.resolve(RecipeDetailsController.self, argument: config)
//
//        recipeDetailsController?.onEvent = { [weak self] event in
//            switch event {
//            case .finish:
//                self?.router.popModule()
//            case .showIngredientInformation(let config):
//                self?.showIngredientDetails(config: config)
//            }
//        }
//
//        router.push(recipeDetailsController)
//    }
//
//    private func showIngredientDetails(config: IngredientDetailsPageViewModel.Config) {
//        let controller = resolver ~> (IngredientDetailsController.self, config)
//        controller.onEvent = { [weak self, weak controller] event in
//            switch event {
//            case .finish:
//                self?.router.dismissModule(controller)
//            }
//        }
//
//        router.present(controller, modalPresentationStyle: .overFullScreen, animated: true)
//    }
}

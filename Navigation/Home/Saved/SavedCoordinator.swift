import Combine
import Swinject
import SwinjectAutoregistration

final class SavedCoordinator: Coordinator {

    enum Event {
        case finish
    }
    var onEvent: ((Event) -> Void)?

    // MARK: - Properties

    lazy var savedNavigationController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private let persistent: Persistent = resolver ~> Persistent.self
    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
        innerRouter = Router(rootController: savedNavigationController)
    }

    override func start() {
        showSavedController()
    }

    // MARK: - Private Methods

    private func showSavedController() {
        let savedController = resolver ~> SavedController.self

        savedController.onEvent = { [weak self] event in
            switch event {
            case .openRecipeDetails(let id):
                self?.openRecipeDetails(with: id)
            case .openCategory(let config):
                self?.openRecipeCollection(with: config)
            }
        }

        savedNavigationController.addChild(savedController)
    }

    private func openRecipeCollection(with config: RecipeCollectionPageViewModel.Config) {
        let recipeCollectionController = resolver.resolve(RecipeCollectionController.self, argument: config)

        recipeCollectionController?.onEvent = { [weak self] event in
            switch event {
            case .openRecipeDetails(let config):
                self?.openRecipeDetails(with: config)
            case .finish:
                self?.router.popModule()
            }
        }

        router.push(recipeCollectionController)
    }

    private func openRecipeDetails(with config: RecipeDetailsPageViewModel.Config) {
        let recipeDetailsController = resolver.resolve(RecipeDetailsController.self, argument: config)

        recipeDetailsController?.onEvent = { [weak self] event in
            switch event {
            case .finish:
                self?.router.popModule()
            case .showIngredientInformation(let config):
                self?.showIngredientDetails(config: config)
            }
        }

        router.push(recipeDetailsController)
    }

    private func showIngredientDetails(config: IngredientDetailsPageViewModel.Config) {
        let controller = resolver ~> (IngredientDetailsController.self, config)
        controller.onEvent = { [weak self, weak controller] event in
            switch event {
            case .finish:
                self?.router.dismissModule(controller)
            }
        }

        router.present(controller, modalPresentationStyle: .overFullScreen, animated: true)
    }
}

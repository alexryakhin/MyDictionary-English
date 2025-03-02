import Combine
import Swinject
import SwinjectAutoregistration

final class SearchCoordinator: Coordinator {

    enum Event {
        case finish
    }
    var onEvent: ((Event) -> Void)?

    // MARK: - Properties

    lazy var searchNavigationController = resolver ~> NavigationController.self

    // MARK: - Private Properties

    private let persistent: Persistent = resolver ~> Persistent.self
    private var innerRouter: RouterInterface!

    // MARK: - Initialization

    required init(router: RouterInterface) {
        super.init(router: router)
        innerRouter = Router(rootController: searchNavigationController)
    }

    override func start() {
        showSearchController()
    }

    // MARK: - Private Methods

    private func showSearchController() {
        let searchController = resolver ~> SearchController.self

        searchController.onEvent = { [weak self] event in
            switch event {
            case .openRecipeDetails(let id):
                self?.openRecipeDetails(with: id)
            }
        }

        searchNavigationController.addChild(searchController)
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

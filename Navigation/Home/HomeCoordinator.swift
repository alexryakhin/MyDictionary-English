import Combine
import Swinject
import SwinjectAutoregistration

final class HomeCoordinator: Coordinator {

    enum Event {
        case authorize
    }
    var onEvent: ((Event) -> Void)?

    private let persistent: Persistent = resolver ~> Persistent.self

    // MARK: - AuthFlowCoordinator

    required init(router: RouterInterface) {
        super.init(router: router)
    }

    override func start() {
        showTabController()
    }

    private func showTabController() {
        guard topController(ofType: TabController.self) == nil else { return }

        let mainNavigationController = assignMainCoordinator()
        let searchNavigationController = assignSearchCoordinator()
        let savedNavigationController = assignSavedCoordinator()
        let shoppingListNavigationController = assignShoppingListCoordinator()

        let controller = resolver ~> TabController.self

        controller.controllers = [
            mainNavigationController,
            searchNavigationController,
            savedNavigationController,
            shoppingListNavigationController
        ]

        router.setRootModule(controller)
    }

    private func assignMainCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: MainAssembly())

        // Main flow coordinator
        guard let mainCoordinator = child(ofType: MainCoordinator.self)
                ?? resolver.resolve(MainCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate MainCoordinator") }
        mainCoordinator.start()

        mainCoordinator.onEvent = { [weak self] event in
            switch event {
            case .authorize:
                self?.onEvent?(.authorize)
            case .openSearchScreen:
                self?.switchTabToSearchController()
            }
        }

        let mainNavigationController = mainCoordinator.mainNavigationController

        if !contains(child: MainCoordinator.self) {
            addDependency(mainCoordinator)
        }

        return mainNavigationController
    }

    private func assignSearchCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: SearchAssembly())

        // Search flow coordinator
        guard let searchCoordinator = child(ofType: SearchCoordinator.self)
                ?? resolver.resolve(SearchCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate SearchCoordinator") }
        searchCoordinator.start()

        searchCoordinator.onEvent = { [weak self] event in
            switch event {
            case .finish:
                break
            }
        }

        let searchNavigationController = searchCoordinator.searchNavigationController

        if !contains(child: SearchCoordinator.self) {
            addDependency(searchCoordinator)
        }

        return searchNavigationController
    }

    private func assignSavedCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: SavedAssembly())

        // Saved flow coordinator
        guard let savedCoordinator = child(ofType: SavedCoordinator.self)
                ?? resolver.resolve(SavedCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate SavedCoordinator") }
        savedCoordinator.start()

        savedCoordinator.onEvent = { [weak self] event in
            switch event {
            case .finish:
                break
            }
        }

        let savedNavigationController = savedCoordinator.savedNavigationController

        if !contains(child: SavedCoordinator.self) {
            addDependency(savedCoordinator)
        }

        return savedNavigationController
    }

    private func assignShoppingListCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: ShoppingListAssembly())

        // ShoppingList flow coordinator
        guard let shoppingListCoordinator = child(ofType: ShoppingListCoordinator.self)
                ?? resolver.resolve(ShoppingListCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate ShoppingListCoordinator") }
        shoppingListCoordinator.start()

        shoppingListCoordinator.onEvent = { [weak self] event in
            switch event {
            case .finish:
                break
            }
        }

        let shoppingListNavigationController = shoppingListCoordinator.shoppingListNavigationController

        if !contains(child: ShoppingListCoordinator.self) {
            addDependency(shoppingListCoordinator)
        }

        return shoppingListNavigationController
    }

    private func assignProfileCoordinator() -> NavigationController {
        DIContainer.shared.assemble(assembly: ProfileAssembly())

        // Profile flow coordinator
        guard let profileCoordinator = child(ofType: ProfileCoordinator.self)
                ?? resolver.resolve(ProfileCoordinator.self, argument: router)
        else { fatalError("Unable to instantiate ProfileCoordinator") }
        profileCoordinator.start()

        profileCoordinator.onEvent = { [weak self] event in
            switch event {
            case .finish:
                break
            }
        }

        let profileNavigationController = profileCoordinator.profileNavigationController

        if !contains(child: ProfileCoordinator.self) {
            addDependency(profileCoordinator)
        }

        return profileNavigationController
    }

    private func switchTabToSearchController() {
        if let tabController = router.firstChild(TabController.self) {
            tabController.controllers.enumerated().forEach { index, controller in
                if let searchController = controller.children.first(SearchController.self) {
                    tabController.forceSwitchTab(to: index)
                    searchController.activateSearch()
                }
            }
        }
    }
}

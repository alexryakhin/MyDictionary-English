// swiftlint:disable final_class
/// Abstract coordinator class
open class BaseCoordinator: CoordinatorInterface {

    typealias DefaultFinishHandler = () -> Void

    var childCoordinators: [CoordinatorInterface] = []

    open func start() {
        assertionFailure("\(String(describing: self)) `start` method must be implemented")
    }

    func addDependency(_ coordinator: CoordinatorInterface) {
        for element in childCoordinators where element === coordinator {
            return
        }
        childCoordinators.append(coordinator)
    }

    func removeDependency(_ coordinator: CoordinatorInterface?) {
        guard
            !childCoordinators.isEmpty,
            let coordinator = coordinator
        else { return }

        for (index, element) in childCoordinators.reversed().enumerated() where element === coordinator {
            childCoordinators.remove(at: childCoordinators.count - index - 1)
            break
        }
    }

    func removeDependency<T: CoordinatorInterface>(of coordinatorType: T.Type) {
        guard !childCoordinators.isEmpty else {
            return
        }

        for (index, element) in childCoordinators.reversed().enumerated() where type(of: element) == coordinatorType {
            childCoordinators.remove(at: childCoordinators.count - index - 1)
            break
        }
    }

    func removeAllDependencies() {
        childCoordinators.removeAll()
    }

    init() { }

    deinit {
        logger.logDeinit(self)
    }
}

extension BaseCoordinator {
    func contains<C: CoordinatorInterface>(child _: C.Type) -> Bool {
        return childCoordinators.contains(where: { type(of: $0) == C.self })
    }

    func child<C: CoordinatorInterface>(ofType _: C.Type) -> C? {
        return childCoordinators.first(where: { type(of: $0) == C.self }) as? C
    }
}

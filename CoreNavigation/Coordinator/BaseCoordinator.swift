import UIKit
import Shared

// swiftlint:disable final_class
/// Abstract coordinator class
open class BaseCoordinator: CoordinatorInterface {

    public typealias DefaultFinishHandler = () -> Void

    public var childCoordinators: [CoordinatorInterface] = []

    open func start() {
        assertionFailure("\(String(describing: self)) `start` method must be implemented")
    }

    public func addDependency(_ coordinator: CoordinatorInterface) {
        for element in childCoordinators where element === coordinator {
            return
        }
        childCoordinators.append(coordinator)
    }

    public func removeDependency(_ coordinator: CoordinatorInterface?) {
        guard
            !childCoordinators.isEmpty,
            let coordinator = coordinator
        else { return }

        for (index, element) in childCoordinators.reversed().enumerated() where element === coordinator {
            childCoordinators.remove(at: childCoordinators.count - index - 1)
            break
        }
    }

    public func removeDependency<T: CoordinatorInterface>(of coordinatorType: T.Type) {
        guard !childCoordinators.isEmpty else {
            return
        }

        for (index, element) in childCoordinators.reversed().enumerated() where type(of: element) == coordinatorType {
            childCoordinators.remove(at: childCoordinators.count - index - 1)
            break
        }
    }

    public func removeAllDependencies() {
        childCoordinators.removeAll()
    }

    public init() { }

    deinit {
        logInfo("DEINIT \(String(describing: self))")
    }
}

public extension BaseCoordinator {
    func contains<C: CoordinatorInterface>(child _: C.Type) -> Bool {
        return childCoordinators.contains(where: { type(of: $0) == C.self })
    }

    func child<C: CoordinatorInterface>(ofType _: C.Type) -> C? {
        return childCoordinators.first(where: { type(of: $0) == C.self }) as? C
    }
}

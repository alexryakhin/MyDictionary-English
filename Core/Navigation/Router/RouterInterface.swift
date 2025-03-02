import UIKit

/// Identical controllers could be pushed one by one
protocol AllowDuplicating {}

enum RouterName {
    static let root = "root"
}

protocol RouterInterface: Presentable {

    var rootController: UINavigationController? { get }

    func present(_ module: Presentable?, modalPresentationStyle: UIModalPresentationStyle, animated: Bool)

    func push(_ module: Presentable?, animated: Bool)
    func pushToTop(_ module: Presentable?, animated: Bool)

    func set(modules: [Presentable], animated: Bool)

    func popModule()
    func popToModule(_ module: Presentable?, animated: Bool)
    func popModule(animated: Bool)
    func popToModule<T: Presentable>(_: T.Type, animated: Bool, failHandler: (() -> Void)?)

    /// Visually navigate back to given module in navigation stack
    func popAndReplaceModule(_ module: Presentable?, animated: Bool)

    func dismissModule()
    func dismissModule(animated: Bool, completion: (() -> Void)?)
    func dismissModule(_ module: Presentable?)
    func dismissModule(_ module: Presentable?, animated: Bool, completion: (() -> Void)?)

    func removeModule<T: Presentable>(_ module: T)

    func setRootModule(_ module: Presentable?, animated: Bool)

    func replaceLast(_ module: Presentable?, animated: Bool)
    func popToRootModule(animated: Bool)

    func addAsChild(_ module: Presentable?)
    func add(_ submodule: Presentable?, asChildTo module: Presentable?)

    func contains<T>(_: T.Type) -> Bool
    func firstChild<T>(_: T.Type) -> T?
    func firstIndex<T>(_ : T.Type) -> Int?
}

extension RouterInterface {

    func present(_ module: Presentable?) {
        present(module, modalPresentationStyle: .automatic, animated: true)
    }

    func push(_ module: Presentable?) {
        push(module, animated: true)
    }

    func pushToTop(_ module: Presentable?) {
        pushToTop(module, animated: true)
    }

    func set(modules: [Presentable]) {
        set(modules: modules, animated: true)
    }

    func dismissModule(_ module: Presentable?) {
        dismissModule(module, animated: true, completion: nil)
    }

    func dismissModule() {
        dismissModule(animated: true, completion: nil)
    }

    func popModule() {
        popModule(animated: true)
    }

    func popToModule(_ module: Presentable?) {
        popToModule(module, animated: true)
    }

    func setRootModule(_ module: Presentable?) {
        setRootModule(module, animated: true)
    }

    func popAndReplaceModule(_ module: Presentable?) {
        popAndReplaceModule(module, animated: true)
    }

    func replaceLast(_ module: Presentable?) {
        replaceLast(module, animated: true)
    }

    func popToModule<T: Presentable>(_: T.Type, animated: Bool) {
        popToModule(T.self, animated: animated, failHandler: nil)
    }

    func popToModule<T: Presentable>(_: T.Type, failHandler: (() -> Void)?) {
        popToModule(T.self, animated: true, failHandler: failHandler)
    }

    func popToModule<T: Presentable>(_: T.Type) {
        popToModule(T.self, animated: true, failHandler: nil)
    }
}

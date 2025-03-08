import Foundation
import UIKit
import Shared

open class Router: NSObject, RouterInterface {
    
    public var rootController: UINavigationController?
    private var completions: [UIViewController: () -> Void]

    public init(rootController: UINavigationController) {
        self.rootController = rootController
        completions = [:]
    }

    public func toPresent() -> UIViewController? {
        return rootController
    }

    public func present(_ module: Presentable?, modalPresentationStyle: UIModalPresentationStyle, animated: Bool) {
        guard let controller = module?.toPresent() else { return }
        controller.modalPresentationStyle = modalPresentationStyle

        var topController: UIViewController? = rootController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        topController?.present(controller, animated: animated, completion: nil)
    }

    public func set(modules: [Presentable], animated: Bool) {
        let controllers = modules.compactMap { $0.toPresent() }
        rootController?.setViewControllers(controllers, animated: animated)
    }

    public func firstIndex<T>(_ : T.Type) -> Int? {
        rootController?.viewControllers.firstIndex(where: { $0 is T })
    }

    public func dismissModule(_ module: Presentable?, animated: Bool, completion: (() -> Void)?) {
        module?.toPresent()?.dismiss(animated: animated, completion: completion)
    }

    public func dismissModule(animated: Bool, completion: (() -> Void)?) {
        rootController?.dismiss(animated: animated, completion: completion)
    }

    public func push(_ module: Presentable?, animated: Bool) {
        guard
            let controller = module?.toPresent(),
            controller is UINavigationController == false
        else {
            assertionFailure("Restricted push UINavigationController at UINavigationController")
            return
        }

        if
            !(module is AllowDuplicating),
            let lastController = rootController?.viewControllers.last,
            type(of: lastController) == type(of: controller) {
            logWarning("Skip duplicating module, check if it is legal and add AllowDuplicating protocol conformance")
            return
        }

        rootController?.pushViewController(controller, animated: animated)
    }

    // Pushes to most top contoller if it is a Navigation Controller
    public func pushToTop(_ module: Presentable?, animated: Bool) {
        guard
            let controller = module?.toPresent(),
            controller is UINavigationController == false
        else {
            assertionFailure("Restricted push UINavigationController at UINavigationController")
            return
        }

        if
            !(module is AllowDuplicating),
            let lastController = rootController?.viewControllers.last,
            type(of: lastController) == type(of: controller) {
            logWarning("Skip duplicating module, check if it is legal and add AllowDuplicating protocol conformance")
            return
        }

        var topController: UIViewController? = rootController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        guard let topController = topController as? UINavigationController else { return }

        topController.pushViewController(controller, animated: animated)
    }

    public func popModule(animated: Bool) {
        if let controller = rootController?.popViewController(animated: animated) {
            runCompletion(for: controller)
        }
    }

    public func popAndReplaceModule(_ module: Presentable?, animated: Bool) {
        guard let rootController else {
            return
        }

        guard
            let module,
            let controller = module.toPresent()
        else {
            popModule(animated: animated)
            return
        }

        guard !rootController.viewControllers.isEmpty else {
            setRootModule(module)
            return
        }

        rootController.viewControllers.insert(controller, at: rootController.viewControllers.count - 1)
        popModule(animated: animated)
    }

    public func removeModule<T: Presentable>(_ module: T) {
        if let controllerIndex = firstIndex(T.self) {
            rootController?.viewControllers.remove(at: controllerIndex)
        }
    }

    public func setRootModule(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent() else {
            return
        }

        rootController?.setViewControllers([controller], animated: animated)
        dismissModule()
    }

    public func replaceLast(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent() else {
            return
        }

        var newControllers = rootController?.viewControllers.dropLast() ?? []
        newControllers.append(controller)

        rootController?.setViewControllers(newControllers, animated: animated)
    }

    public func popToModule(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent() else {
            return
        }

        rootController?.popToViewController(controller, animated: animated)?.forEach { controller in
            runCompletion(for: controller)
        }
    }

    public func popToModule<T: Presentable>(_: T.Type, animated: Bool, failHandler: (() -> Void)?) {
        guard let module = firstChild(T.self) else {
            failHandler?()
            return
        }

        popToModule(module, animated: animated)
    }

    public func popToRootModule(animated: Bool) {
        if let controllers = rootController?.popToRootViewController(animated: animated) {
            controllers.forEach { controller in
                runCompletion(for: controller)
            }
        }
    }

    public func addAsChild(_ module: Presentable?) {
        guard
            let rootController = rootController,
            let controller = module?.toPresent() else {
            return
        }

        controller.view.frame = controller.view.bounds
        rootController.addChild(controller)
        rootController.view.addSubview(controller.view)
    }

    public func add(_ submodule: Presentable?, asChildTo module: Presentable?) {
        guard
            let subcontroller = submodule?.toPresent(),
            let controller = module?.toPresent()
        else {
            return
        }

        subcontroller.view.frame = subcontroller.view.bounds
        controller.addChild(subcontroller)
        controller.view.addSubview(subcontroller.view)
    }

    private func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else { return }
        completion()
        completions.removeValue(forKey: controller)
    }

    public func contains<T>(_: T.Type) -> Bool {
        return rootController?.viewControllers.contains(T.self) ?? false
    }

    public func firstChild<T>(_: T.Type) -> T? {
        return rootController?.viewControllers.first(T.self)
    }

    deinit {
        logInfo("DEINIT: \(String(describing: type(of: self)))")
    }
}

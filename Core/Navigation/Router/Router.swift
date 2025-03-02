import Foundation
import UIKit

open class Router: NSObject, RouterInterface {
    
    var rootController: UINavigationController?
    private var completions: [UIViewController: () -> Void]

    init(rootController: UINavigationController) {
        self.rootController = rootController
        completions = [:]
    }

    func toPresent() -> UIViewController? {
        return rootController
    }

    func present(_ module: Presentable?, modalPresentationStyle: UIModalPresentationStyle, animated: Bool) {
        guard let controller = module?.toPresent() else { return }
        controller.modalPresentationStyle = modalPresentationStyle

        var topController: UIViewController? = rootController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        topController?.present(controller, animated: animated, completion: nil)
    }

    func set(modules: [Presentable], animated: Bool) {
        let controllers = modules.compactMap { $0.toPresent() }
        rootController?.setViewControllers(controllers, animated: animated)
    }

    func firstIndex<T>(_ : T.Type) -> Int? {
        rootController?.viewControllers.firstIndex(where: { $0 is T })
    }

    func dismissModule(_ module: Presentable?, animated: Bool, completion: (() -> Void)?) {
        module?.toPresent()?.dismiss(animated: animated, completion: completion)
    }

    func dismissModule(animated: Bool, completion: (() -> Void)?) {
        rootController?.dismiss(animated: animated, completion: completion)
    }

    func push(_ module: Presentable?, animated: Bool) {
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
            warn("Skip duplicating module, check if it is legal and add AllowDuplicating protocol conformance")
            return
        }

        rootController?.pushViewController(controller, animated: animated)
    }

    // Pushes to most top contoller if it is a Navigation Controller
    func pushToTop(_ module: Presentable?, animated: Bool) {
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
            warn("Skip duplicating module, check if it is legal and add AllowDuplicating protocol conformance")
            return
        }

        var topController: UIViewController? = rootController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        guard let topController = topController as? UINavigationController else { return }

        topController.pushViewController(controller, animated: animated)
    }

    func popModule(animated: Bool) {
        if let controller = rootController?.popViewController(animated: animated) {
            runCompletion(for: controller)
        }
    }

    func popAndReplaceModule(_ module: Presentable?, animated: Bool) {
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

    func removeModule<T: Presentable>(_ module: T) {
        if let controllerIndex = firstIndex(T.self) {
            rootController?.viewControllers.remove(at: controllerIndex)
        }
    }

    func setRootModule(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent() else {
            return
        }

        rootController?.setViewControllers([controller], animated: animated)
        dismissModule()
    }

    func replaceLast(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent() else {
            return
        }

        var newControllers = rootController?.viewControllers.dropLast() ?? []
        newControllers.append(controller)

        rootController?.setViewControllers(newControllers, animated: animated)
    }

    func popToModule(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent() else {
            return
        }

        rootController?.popToViewController(controller, animated: animated)?.forEach { controller in
            runCompletion(for: controller)
        }
    }

    func popToModule<T: Presentable>(_: T.Type, animated: Bool, failHandler: (() -> Void)?) {
        guard let module = firstChild(T.self) else {
            failHandler?()
            return
        }

        popToModule(module, animated: animated)
    }

    func popToRootModule(animated: Bool) {
        if let controllers = rootController?.popToRootViewController(animated: animated) {
            controllers.forEach { controller in
                runCompletion(for: controller)
            }
        }
    }

    func addAsChild(_ module: Presentable?) {
        guard
            let rootController = rootController,
            let controller = module?.toPresent() else {
            return
        }

        controller.view.frame = controller.view.bounds
        rootController.addChild(controller)
        rootController.view.addSubview(controller.view)
    }

    func add(_ submodule: Presentable?, asChildTo module: Presentable?) {
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

    func contains<T>(_: T.Type) -> Bool {
        return rootController?.viewControllers.contains(T.self) ?? false
    }

    func firstChild<T>(_: T.Type) -> T? {
        return rootController?.viewControllers.first(T.self)
    }

    deinit {
        logger.logDeinit(self)
    }
}

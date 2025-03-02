//
//  AppAssembly.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/29/24.
//

import Swinject
import SwinjectAutoregistration
import UIKit

final class AppAssembly: Assembly, Identifiable {

    let id = "AppAssembly"

    weak var window: BaseWindow!

    init(window: BaseWindow) {
        self.window = window
    }

    func assemble(container: Container) {
        container.register(NavigationController.self) { _ in
            NavigationController(navigationBarClass: NavigationBar.self, toolbarClass: nil)
        }

        container.register(RouterInterface.self, name: RouterName.root) { resolver in
            let navigationController = resolver ~> NavigationController.self
            return Router(rootController: navigationController)
        }

        container.register(LaunchFlowCheckerInterface.self) { resolver in
            return LaunchFlowChecker()
        }

        container.register(AppCoordinator.self) { resolver in
            let persistent = (resolver ~> ServiceLayer.self).persistent
            let router = resolver ~> (RouterInterface.self, name: RouterName.root)
            return AppCoordinator(window: self.window, router: router)
        }
        .inObjectScope(.container)
    }
}

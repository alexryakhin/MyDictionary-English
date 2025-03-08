//
//  AppAssembly.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import CoreNavigation
import CoreUserInterface
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

        container.register(AppCoordinator.self) { resolver in
            let router = resolver ~> (RouterInterface.self, name: RouterName.root)
            return AppCoordinator(window: self.window, router: router)
        }
        .inObjectScope(.container)
    }
}

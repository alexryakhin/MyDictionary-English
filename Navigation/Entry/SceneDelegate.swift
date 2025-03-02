//
//  SceneDelegate.swift
//  MyDictionary
//
//  Created by Aleksandr Riakhin on 9/30/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = BaseWindow(windowScene: windowScene)
        let diContainer = DIContainer.shared
        diContainer.assemble(assembly: AppAssembly(window: window))

        let deeplinkActivity = connectionOptions.userActivities.first

        guard let appCoordinator = diContainer.resolver.resolve(AppCoordinator.self) else {
            fatalError("Failed to init AppCoordinator")
        }

        self.appCoordinator = appCoordinator

        appCoordinator.start()
    }
}

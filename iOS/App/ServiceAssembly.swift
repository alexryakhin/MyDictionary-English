//
//  ServiceAssembly.swift
//  MyDictionaryApp
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import Swinject
import SwinjectAutoregistration

final class ServiceAssembly: Assembly, Identifiable {

    var id: String = "ServiceAssembly"

    func assemble(container: Container) {
        container.register(WordnikApiServiceInterface.self) { _ in
            WordnikApiService()
        }
        .inObjectScope(.container)

        container.register(WordsProviderInterface.self) { _ in
            WordsProvider()
        }
        .inObjectScope(.container)

        container.register(WordsManagerInterface.self) { _ in
            WordsManager()
        }
        .inObjectScope(.container)

        container.register(IdiomsProviderInterface.self) { _ in
            IdiomsProvider()
        }
        .inObjectScope(.container)

        container.register(IdiomsManagerInterface.self) { _ in
            IdiomsManager()
        }
        .inObjectScope(.container)
    }
}

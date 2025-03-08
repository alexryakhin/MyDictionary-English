//
//  ServicesAssembly.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Swinject
import SwinjectAutoregistration
import Foundation
import Services
import Shared

final class ServicesAssembly: Assembly, Identifiable {

    let id = "ServicesAssembly"

    func assemble(container: Container) {

        container.register(JSONEncoder.self) { _ in
            let encoder = JSONEncoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            encoder.dateEncodingStrategy = .formatted(formatter)
            encoder.outputFormatting = .sortedKeys
            return encoder
        }.inObjectScope(.container)

        container.register(JSONDecoder.self) { _ in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                let formatter = DateFormatter()

                if let date = formatter.convertStringToDate(string: dateString, format: .iso) {
                    return date
                }
                if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd'T'HH:mm:ss'Z'") {
                    return date
                }
                if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd'T'HH:mm:ss") {
                    return date
                }
                if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd'T'HH:mm") {
                    return date
                }
                if let date = formatter.convertStringToDate(string: dateString, formatString: "yyyy-MM-dd") {
                    return date
                }
                if let date = formatter.convertStringToDate(string: String(dateString.prefix(10)), formatString: "yyyy-MM-dd") {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            return decoder
        }.inObjectScope(.container)

//        container.autoregister(FeatureToggleServiceInterface.self, initializer: FeatureToggleService.init)
//            .inObjectScope(.container)
//
//        container.register(NetworkServiceInterface.self) { resolver in
//            NetworkService(
//                featureToggleService: resolver ~> FeatureToggleServiceInterface.self,
//                errorParser: ErrorParser()
//            )
//        }.inObjectScope(.container)

//        container.register(SpoonacularNetworkServiceInterface.self) { resolver in
//            SpoonacularNetworkService(
//                networkService: resolver ~> NetworkServiceInterface.self,
//                apiKeyManager: resolver ~> SpoonacularAPIKeyManagerInterface.self
//            )
//        }.inObjectScope(.container)

        container.register(CoreDataServiceInterface.self) { resolver in
            CoreDataService()
        }
        .inObjectScope(.container)

        container.register(WordsProviderInterface.self) { resolver in
            WordsProvider(coreDataService: resolver ~> CoreDataServiceInterface.self)
        }
        .inObjectScope(.container)

        container.register(WordsManagerInterface.self) { resolver in
            WordsManager(coreDataService: resolver ~> CoreDataServiceInterface.self)
        }
        .inObjectScope(.container)

        container.register(IdiomsProviderInterface.self) { resolver in
            IdiomsProvider(coreDataService: resolver ~> CoreDataServiceInterface.self)
        }
        .inObjectScope(.container)

        container.register(IdiomsManagerInterface.self) { resolver in
            IdiomsManager(coreDataService: resolver ~> CoreDataServiceInterface.self)
        }
        .inObjectScope(.container)
    }

    func loaded(resolver: Resolver) {
        logInfo("Services Assembly is loaded")
    }
}

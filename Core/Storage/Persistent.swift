//
//  Persistent.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/2/24.
//
import Combine

enum Property {
    case environment(AppEnvironment)
    case fcmToken(String)
    case lastUsedAppVersion(String)
    case isOnboardingAlreadyShown(Bool)
}

enum PropertyKey {
    static let environment = "Environment"
    static let fcmToken = "FcmToken"
    static let lastUsedAppVersion = "LastUsedAppVersion"
    static let isOnboardingAlreadyShown = "IsOnboardingAlreadyShown"
}

protocol Persistent: AnyObject {

    func set(_ property: Property)

    var environment: AppEnvironment { get }
    var fcmToken: String? { get }

    // Auth Properties
    var lastUsedAppVersion: String? { get }
    var isFirstLaunch: Bool { get }
    var isOnboardingFlowShown: Bool { get }
}

final class PersistentLayer: Persistent {

    var environment: AppEnvironment
    var fcmToken: String?

    var lastUsedAppVersion: String?

    // Auth Properties
    var isFirstLaunch: Bool { lastUsedAppVersion == nil }
    var isOnboardingFlowShown: Bool

    let userDefaultsStorage: UserDefaultsServiceInterface

    init() {
        userDefaultsStorage = UserDefaultsService()

        if
            let environmentName = userDefaultsStorage.loadString(forKey: PropertyKey.environment),
            let savedEnvironment = AppEnvironment.named(environmentName) {
            environment = savedEnvironment
        } else {
            #if DEBUG
            environment = AppEnvironment.debug
            #else
            environment = AppEnvironment.release
            #endif
        }

        fcmToken = userDefaultsStorage.loadString(forKey: PropertyKey.fcmToken)
        lastUsedAppVersion = userDefaultsStorage.loadString(forKey: PropertyKey.lastUsedAppVersion)
        isOnboardingFlowShown = userDefaultsStorage.loadBool(forKey: PropertyKey.isOnboardingAlreadyShown)
    }

    func set(_ property: Property) {
        switch property {
        case .environment(let environment):
            self.environment = environment
            userDefaultsStorage.save(string: environment.name, forKey: PropertyKey.environment)
        case .fcmToken(let fcmToken):
            self.fcmToken = fcmToken
            userDefaultsStorage.save(string: fcmToken, forKey: PropertyKey.fcmToken)
        case .isOnboardingAlreadyShown(let isShown):
            isOnboardingFlowShown = isShown
            userDefaultsStorage.save(bool: isShown, forKey: PropertyKey.isOnboardingAlreadyShown)
        case .lastUsedAppVersion(let version):
            lastUsedAppVersion = version
            userDefaultsStorage.save(string: version, forKey: PropertyKey.lastUsedAppVersion)
        }
    }
}

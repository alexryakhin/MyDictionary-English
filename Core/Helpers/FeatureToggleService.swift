//
//  FeatureToggleServiceInterface.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/6/24.
//

import Foundation
//import FirebaseRemoteConfig
import Combine

enum FeatureToggle: String, CaseIterable {

    case mock_data

    var isEnabledByDefault: Bool {
        switch self {
        case .mock_data: true
        }
    }

    var title: String {
        switch self {
        case .mock_data: "Use mock data if available for requests."
        }
    }
}

typealias FeatureToggles = [FeatureToggle: Bool]

protocol FeatureToggleServiceInterface: AnyObject {
    var featureToggles: CurrentValueSubject<FeatureToggles, Never> { get }

//    func fetchRemoteConfig()
}

final class FeatureToggleService: FeatureToggleServiceInterface {

    let featureToggles = CurrentValueSubject<FeatureToggles, Never>([:])

//    private let remoteConfig = RemoteConfig.remoteConfig()
    private var cancellables = Set<AnyCancellable>()

    init() {
//        setupMinimumFetchInterval()
        setDefaults()
    }

//    func fetchRemoteConfig() {
//        debug("Fetching remote config")
//        remoteConfig.fetchAndActivate { [weak self] _, error in
//            guard error == nil else {
//                fault("Fetching remote config finished with error: \(String(describing: error))")
//                return
//            }
//            self?.setValues()
//        }
//    }

    private func setDefaults() {
        let defaults = Dictionary(uniqueKeysWithValues: FeatureToggle.allCases.map({ toggle in
            (toggle.rawValue, NSNumber(booleanLiteral: toggle.isEnabledByDefault))
        }))
//        remoteConfig.setDefaults(defaults)
        setValues()
    }

    private func setValues() {
        var toggles = FeatureToggles()
        for toggle in FeatureToggle.allCases {
//            toggles[toggle] = remoteConfig.configValue(forKey: toggle.rawValue).boolValue
            toggles[toggle] = toggle.isEnabledByDefault
        }
        featureToggles.send(toggles)
    }

//    private func setupMinimumFetchInterval(_ interval: TimeInterval = 180) {
//        let settings = RemoteConfigSettings()
//        settings.minimumFetchInterval = interval
//        remoteConfig.configSettings = settings
//    }
}

extension FeatureToggles {
    func isEnabled(_ feature: FeatureToggle) -> Bool {
        self[feature] == true
    }
}

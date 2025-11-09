//
//  AnalyticsService.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/9/25.
//

import FirebaseAnalytics

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    func logEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        #if DEBUG
        logInfo("[AnalyticsService] Log event: \(event.rawValue), parameters: \(String(describing: parameters))")
        #else
        Analytics.logEvent(event.rawValue, parameters: parameters ?? event.parameters)
        #endif
    }
}

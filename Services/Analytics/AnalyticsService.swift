//
//  AnalyticsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import FirebaseAnalytics

protocol AnalyticsServiceInterface {
    func logEvent(_ event: AnalyticsEvent)
}

struct AnalyticsService: AnalyticsServiceInterface {

    static let shared: AnalyticsServiceInterface = AnalyticsService()

    private init() {}

    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.rawValue, parameters: event.parameters)
        logInfo("Analytics log event: \(event.rawValue)")
    }
}

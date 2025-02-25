//
//  AnalyticsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Firebase
import FirebaseAnalytics

protocol AnalyticsServiceInterface {
    func logEvent(_ event: AnalyticsEvent)
}

final class AnalyticsService: AnalyticsServiceInterface {

    static let shared: AnalyticsServiceInterface = AnalyticsService()

    private init() {}

    func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.rawValue, parameters: event.parameters)
    }
}

//
//  AnalyticsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import FirebaseAnalytics

public protocol AnalyticsServiceInterface {
    func logEvent(_ event: AnalyticsEvent)
}

public struct AnalyticsService: AnalyticsServiceInterface {

    public static let shared: AnalyticsServiceInterface = AnalyticsService()

    private init() {}

    public func logEvent(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.rawValue, parameters: event.parameters)
    }
}

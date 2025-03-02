//
//  CrashlyticsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/25/25.
//

import Firebase
import FirebaseCrashlytics

final class CrashlyticsService {
    static func logCustomError(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}

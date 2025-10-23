//
//  SubscriptionPeriod+Extension.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/23/25.
//

import Foundation
import RevenueCat

extension SubscriptionPeriod.Unit {
    var displayName: String {
        switch self {
        case .day: return Loc.Subscription.Period.day
        case .week: return Loc.Subscription.Period.week
        case .month: return Loc.Subscription.Period.month
        case .year: return Loc.Subscription.Period.year
        }
    }
}

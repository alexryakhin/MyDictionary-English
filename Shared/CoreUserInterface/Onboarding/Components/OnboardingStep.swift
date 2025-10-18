//
//  OnboardingStep.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 10/17/25.
//

import Foundation

extension OnboardingFlow {
    enum Step: Int, Hashable, CaseIterable {
        case welcome
        case name
        case userType
        case ageGroup
        case goals
        case languages
        case interests
        case studyIntensity
        case studyTime
        case streak
        case notifications
        case paywall
        case success
    }
}

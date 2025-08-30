//
//  SignInFeature.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/30/25.
//

import Foundation
import SwiftUI

enum SignInFeature: CaseIterable {
    case syncWords
    case useAI
    
    var displayTitle: String {
        switch self {
        case .syncWords:
            return Loc.Auth.signInToSyncWordLists
        case .useAI:
            return Loc.Ai.aiSignInRequired
        }
    }
    
    var displayMessage: String {
        switch self {
        case .syncWords:
            return Loc.Auth.signInToAccessWordLists
        case .useAI:
            return Loc.Ai.aiSignInRequiredMessage
        }
    }
    
    var iconName: String {
        switch self {
        case .syncWords:
            return "arrow.triangle.2.circlepath"
        case .useAI:
            return "brain.head.profile"
        }
    }
}

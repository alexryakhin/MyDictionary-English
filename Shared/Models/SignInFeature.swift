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

    var displayTitle: String {
        switch self {
        case .syncWords:
            return Loc.Auth.signInToSyncWordLists
        }
    }
    
    var displayMessage: String {
        switch self {
        case .syncWords:
            return Loc.Auth.signInToAccessWordLists
        }
    }
    
    var iconName: String {
        switch self {
        case .syncWords:
            return "arrow.triangle.2.circlepath"
        }
    }
}

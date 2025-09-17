//
//  FeatureToggleItem.swift
//  My Dictionary
//
//  Created by AI Assistant on 1/27/25.
//

import Foundation

/// Enum representing feature toggle items that can be controlled via Firebase Remote Config
enum FeatureToggleItem: String, CaseIterable {
    case wordCollectionFeature = "word_collection_feature"
    case learnFeature = "learn_feature"
    
    /// Returns the default enabled state for each feature toggle
    var isEnabledByDefault: Bool {
        switch self {
        case .wordCollectionFeature:
            return true
        case .learnFeature:
            return false
        }
    }
}

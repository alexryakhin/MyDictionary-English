//
//  TagColor.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

enum TagColor: String, CaseIterable {
    case blue = "blue"
    case red = "red"
    case green = "green"
    case orange = "orange"
    case purple = "purple"
    case pink = "pink"
    case yellow = "yellow"
    case gray = "gray"
    
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .red:
            return .red
        case .green:
            return .green
        case .orange:
            return .orange
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .yellow:
            return .yellow
        case .gray:
            return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .blue:
            return Loc.TagColors.blue.localized
        case .red:
            return Loc.TagColors.red.localized
        case .green:
            return Loc.TagColors.green.localized
        case .orange:
            return Loc.TagColors.orange.localized
        case .purple:
            return Loc.TagColors.purple.localized
        case .pink:
            return Loc.TagColors.pink.localized
        case .yellow:
            return Loc.TagColors.yellow.localized
        case .gray:
            return Loc.TagColors.gray.localized
        }
    }
} 
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
            return "Blue"
        case .red:
            return "Red"
        case .green:
            return "Green"
        case .orange:
            return "Orange"
        case .purple:
            return "Purple"
        case .pink:
            return "Pink"
        case .yellow:
            return "Yellow"
        case .gray:
            return "Gray"
        }
    }
} 
//
//  InputState.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

enum InputState: Equatable {
    case pending
    case error
    case focused

    var rawValue: Int {
        switch self {
        case .pending: return 0
        case .error: return 1
        case .focused: return 2
        }
    }

    var backgroundColor: Color {
        switch self {
        case .pending, .focused: Color(.underPageBackgroundColor)
        case .error: .red
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

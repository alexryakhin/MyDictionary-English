//
//  TabBarItem.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum TabBarItem: CaseIterable {
    case words
    case idioms
    case quizzes
    case analytics
    case settings

    var title: String {
        switch self {
        case .words:
            return Loc.words.localized
        case .idioms:
            return Loc.idioms.localized
        case .quizzes:
            return Loc.quizzes.localized
        case .analytics:
            return Loc.progress.localized
        case .settings:
            return Loc.settings.localized
        }
    }

    var image: String {
        switch self {
        case .words:
            return "textformat"
        case .idioms:
            return "quote.bubble"
        case .quizzes:
            return "brain.head.profile"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        case .settings:
            return "gearshape"
        }
    }

    var selectedImage: String {
        switch self {
        case .words:
            return "textformat"
        case .idioms:
            return "quote.bubble.fill"
        case .quizzes:
            return "brain.head.profile"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        case .settings:
            return "gearshape.fill"
        }
    }
}

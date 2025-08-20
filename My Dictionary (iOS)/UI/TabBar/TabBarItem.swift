//
//  TabBarItem.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

enum TabBarItem: CaseIterable {
    case myDictionary
    case quizzes
    case analytics
    case settings

    var title: String {
        switch self {
        case .myDictionary:
            return Loc.App.myDictionary.localized
        case .quizzes:
            return Loc.TabBar.quizzes.localized
        case .analytics:
            return Loc.TabBar.progress.localized
        case .settings:
            return Loc.TabBar.settings.localized
        }
    }

    var image: String {
        switch self {
        case .myDictionary:
            return "textformat"
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
        case .myDictionary:
            return "textformat"
        case .quizzes:
            return "brain.head.profile"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        case .settings:
            return "gearshape.fill"
        }
    }
}

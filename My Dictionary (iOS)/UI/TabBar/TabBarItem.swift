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
            return Loc.Onboarding.myDictionary
        case .quizzes:
            return Loc.Navigation.Tabbar.quizzes
        case .analytics:
            return Loc.Navigation.Tabbar.progress
        case .settings:
            return Loc.Navigation.Tabbar.settings
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
            return "brain.head.profile.fill"
        case .analytics:
            return "chart.line.uptrend.xyaxis"
        case .settings:
            return "gearshape.fill"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

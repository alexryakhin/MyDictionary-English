//
//  TabBarItem.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import UIKit

enum TabBarItem: CaseIterable {
    case words
    case idioms
    case quizzes
    case analytics
    case settings

    var title: String {
        switch self {
        case .words:
            return "Words"
        case .idioms:
            return "Idioms"
        case .quizzes:
            return "Quizzes"
        case .analytics:
            return "Progress"
        case .settings:
            return "Settings"
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

    var item: UITabBarItem {
        UITabBarItem(
            title: title,
            image: .init(systemName: image),
            selectedImage: .init(systemName: selectedImage)
        )
    }
}

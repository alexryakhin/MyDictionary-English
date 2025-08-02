//
//  TabBarItem.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import UIKit

enum TabBarItem: String, CaseIterable, Identifiable {
    case words
    case idioms
    case quizzes
    case analytics
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .words: "Words"
        case .idioms: "Idioms"
        case .quizzes: "Quizzes"
        case .analytics: "Progress"
        case .more: "More"
        }
    }

    var image: String {
        switch self {
        case .words: "textformat.abc"
        case .idioms: "scroll"
        case .quizzes: "a.magnify"
        case .analytics: "chart.line.uptrend.xyaxis"
        case .more: "ellipsis.circle"
        }
    }

    var selectedImage: String {
        switch self {
        case .words: "textformat.abc.fill"
        case .idioms: "scroll.fill"
        case .quizzes: "a.magnify.fill"
        case .analytics: "chart.line.uptrend.xyaxis.fill"
        case .more: "ellipsis.circle.fill"
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

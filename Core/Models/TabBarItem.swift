//
//  TabBarItem.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import UIKit

public enum TabBarItem: String, CaseIterable, Identifiable {
    case words
    case idioms
    case quizzes
    case more

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .words: "Words"
        case .idioms: "Idioms"
        case .quizzes: "Quizzes"
        case .more: "More"
        }
    }

    public var image: String {
        switch self {
        case .words: "textformat.abc"
        case .idioms: "scroll"
        case .quizzes: "a.magnify"
        case .more: "ellipsis.circle"
        }
    }

    public var selectedImage: String {
        switch self {
        case .words: "textformat.abc.fill"
        case .idioms: "scroll.fill"
        case .quizzes: "a.magnify.fill"
        case .more: "ellipsis.circle.fill"
        }
    }

    public var item: UITabBarItem {
        UITabBarItem(
            title: title,
            image: .init(systemName: image),
            selectedImage: .init(systemName: selectedImage)
        )
    }
}

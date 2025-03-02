import SwiftUI

enum TabBarItem: String, CaseIterable, Identifiable {
    case words
    case idioms
    case quizzes
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .words: "Words"
        case .idioms: "Idioms"
        case .quizzes: "Quizzes"
        case .settings: "Settings"
        }
    }

    var image: String {
        switch self {
        case .words: "textformat.abc"
        case .idioms: "scroll"
        case .quizzes: "a.magnify"
        case .settings: "gearshape"
        }
    }

    var selectedImage: String {
        switch self {
        case .words: "textformat.abc.fill"
        case .idioms: "scroll.fill"
        case .quizzes: "a.magnify.fill"
        case .settings: "gearshape.fill"
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

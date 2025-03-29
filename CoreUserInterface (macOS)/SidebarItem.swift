import SwiftUI

public enum SidebarItem: Hashable, CaseIterable {
    case words
    case idioms
    case quizzes

    public var title: String {
        switch self {
        case .words:
            return "Words"
        case .idioms:
            return "Idioms"
        case .quizzes:
            return "Quizzes"
        }
    }

    public var image: Image {
        switch self {
        case .words:
            return Image(systemName: "textformat.abc")
        case .idioms:
            return Image(systemName: "scroll")
        case .quizzes:
            return Image(systemName: "a.magnify")
        }
    }
}

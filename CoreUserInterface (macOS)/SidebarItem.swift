import SwiftUI

public enum SidebarItem: Hashable, CaseIterable {
    case words
    case idioms
    case quizzes

    public var title: String {
        switch self {
        case .words: "Words"
        case .idioms: "Idioms"
        case .quizzes: "Quizzes"
        }
    }

    public var imageSystemName: String {
        switch self {
        case .words: "textformat.abc"
        case .idioms: "scroll"
        case .quizzes: "a.magnify"
        }
    }
}

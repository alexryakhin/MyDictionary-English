import SwiftUI

enum SidebarItem: Hashable, CaseIterable {
    case words
    case idioms
    case quizzes

    var title: String {
        switch self {
        case .words: "Words"
        case .idioms: "Idioms"
        case .quizzes: "Quizzes"
        }
    }

    var imageSystemName: String {
        switch self {
        case .words: "textformat.abc"
        case .idioms: "scroll"
        case .quizzes: "a.magnify"
        }
    }
}

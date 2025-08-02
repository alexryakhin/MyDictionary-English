import SwiftUI

enum SidebarItem: Hashable, CaseIterable {
    case words
    case idioms
    case quizzes
    case progress

    var title: String {
        switch self {
        case .words: "Words"
        case .idioms: "Idioms"
        case .quizzes: "Quizzes"
        case .progress: "Progress"
        }
    }

    var imageSystemName: String {
        switch self {
        case .words: "textformat.abc"
        case .idioms: "scroll"
        case .quizzes: "a.magnify"
        case .progress: "chart.line.uptrend.xyaxis"
        }
    }
}

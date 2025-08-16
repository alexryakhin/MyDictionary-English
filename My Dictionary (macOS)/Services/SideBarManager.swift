import Foundation
import SwiftUI
import Combine

final class SideBarManager: ObservableObject {

    enum QuizItem: Hashable {
        case chooseDefinition(QuizPreset)
        case spelling(QuizPreset)
    }

    enum DetailItem: Hashable {
        case word(CDWord)
        case sharedWord(SharedWord, dictionaryId: String)
        case idiom(CDIdiom)
        case quiz(QuizItem)
    }

    static let shared = SideBarManager()
    
    @Published var selectedTab: SideBarTab? = .words

    @Published var selectedWord: CDWord? = nil
    @Published var selectedSharedWord: SharedWord? = nil
    @Published var selectedIdiom: CDIdiom? = nil
    @Published var selectedQuiz: QuizItem? = nil

    var selectedDetailItem: DetailItem? {
        if let selectedWord = selectedWord {
            return .word(selectedWord)
        } else if
            let selectedSharedWord = selectedSharedWord,
            case .sharedDictionary(let dictionary) = selectedTab {
            return .sharedWord(selectedSharedWord, dictionaryId: dictionary.id)
        } else if let selectedIdiom = selectedIdiom{
            return .idiom(selectedIdiom)
        } else if let selectedQuiz = selectedQuiz {
            return .quiz(selectedQuiz)
        } else {
            return nil
        }
    }

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        setupBindings()
    }

    private func setupBindings() {
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.resetDetails()
            }
            .store(in: &cancellables)
    }

    private func resetDetails() {
        selectedWord = nil
        selectedSharedWord = nil
        selectedIdiom = nil
        selectedQuiz = nil
    }
}

enum SideBarTab: Hashable {
    case words
    case idioms
    case quizzes
    case analytics
    case sharedDictionary(SharedDictionary)

    var title: String {
        switch self {
        case .words: return Loc.words.localized
        case .idioms: return Loc.idioms.localized
        case .quizzes: return Loc.quizzes.localized
        case .analytics: return Loc.progress.localized
        case .sharedDictionary(let dictionary): return dictionary.name
        }
    }
    
    var systemImage: String {
        switch self {
        case .words: return "textformat.abc"
        case .idioms: return "quote.bubble"
        case .quizzes: return "questionmark.circle"
        case .analytics: return "chart.bar"
        case .sharedDictionary: return "person"
        }
    }

    var selectDetailsText: String? {
        switch self {
        case .words: Loc.selectWord.localized
        case .idioms: Loc.selectIdiom.localized
        case .quizzes: Loc.selectQuiz.localized
        case .analytics: nil
        case .sharedDictionary: Loc.selectWord.localized
        }
    }

    static let tabs: [SideBarTab] = [.words, .idioms, .quizzes, .analytics]
}

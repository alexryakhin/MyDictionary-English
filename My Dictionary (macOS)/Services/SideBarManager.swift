import Foundation
import SwiftUI
import Combine

final class SideBarManager: ObservableObject {

    enum QuizItem: Hashable {
        case chooseDefinition(QuizPreset)
        case spelling(QuizPreset)
        case sentenceWriting(QuizPreset)
        case contextMultipleChoice(QuizPreset)
        case fillInTheBlank(QuizPreset)
    }

    enum DetailItem: Hashable {
        case word(CDWord)
        case sharedWord(SharedWord, dictionaryId: String)
        case idiom(CDWord)
        case quiz(QuizItem)
    }

    static let shared = SideBarManager()
    
    @Published var selectedTab: SideBarTab? = .myDictionary

    @Published var selectedWord: CDWord? = nil {
        willSet {
            if selectedIdiom != nil {
                selectedIdiom = nil
            }
        }
    }
    @Published var selectedSharedWord: SharedWord? = nil
    @Published var selectedIdiom: CDWord? = nil {
        willSet {
            if selectedWord != nil {
                selectedWord = nil
            }
        }
    }
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
    case myDictionary
    case quizzes
    case analytics
    case sharedDictionary(SharedDictionary)

    var title: String {
        switch self {
        case .myDictionary: return Loc.Onboarding.myDictionary
        case .quizzes: return Loc.Navigation.Tabbar.quizzes
        case .analytics: return Loc.Navigation.Tabbar.progress
        case .sharedDictionary(let dictionary): return dictionary.name
        }
    }
    
    var systemImage: String {
        switch self {
        case .myDictionary: return "textformat"
        case .quizzes: return "questionmark.circle"
        case .analytics: return "chart.bar"
        case .sharedDictionary: return "person"
        }
    }

    var selectDetailsText: String? {
        switch self {
        case .myDictionary: Loc.Actions.selectWord
        case .quizzes: Loc.Actions.selectQuiz
        case .analytics: nil
        case .sharedDictionary: Loc.Actions.selectWord
        }
    }

    static let tabs: [SideBarTab] = [.myDictionary, .quizzes, .analytics]
}

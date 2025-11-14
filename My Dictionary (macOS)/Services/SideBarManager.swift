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
        case pronunciationPractice(QuizPreset)
        case storyLab(StoryLabConfig)
    }

    enum DetailItem: Hashable {
        case word(CDWord)
        case sharedWord(SharedWord, dictionaryId: String)
        case idiom(CDWord)
        case quiz(QuizItem)
        case wordCollection(WordCollection)
        case discover(DiscoverDetail)
    }

    enum DiscoverDetail: Hashable {
        case music(MusicDetail)
        case story(StoryDetail)

        enum MusicDetail: Hashable {
            case overview
            case songInfo(song: Song)
            case lessonResults(session: MusicDiscoveringSession, song: Song)
        }

        enum StoryDetail: Hashable {
            case overview
            case loading
            case reading(config: StoryLabConfig)
            case results(config: StoryLabResultsConfig)
            case error(String)
        }
    }

    static let shared = SideBarManager()
    
    @Published var selectedTab: SideBarTab? = .myDictionary

    @Published var selectedWord: CDWord? = nil
    @Published var selectedSharedWord: SharedWord? = nil
    @Published var selectedIdiom: CDWord? = nil
    @Published var selectedQuiz: QuizItem? = nil
    @Published var selectedWordCollection: WordCollection? = nil
    @Published var discoverDetail: DiscoverDetail? = nil

    var selectedDetailItem: DetailItem? {
        if let selectedWord = selectedWord {
            return .word(selectedWord)
        } else if
            let selectedSharedWord = selectedSharedWord,
            case .sharedDictionary(let dictionary) = selectedTab {
            return .sharedWord(selectedSharedWord, dictionaryId: dictionary.id)
        } else if let selectedIdiom = selectedIdiom {
            return .idiom(selectedIdiom)
        } else if let selectedQuiz = selectedQuiz {
            return .quiz(selectedQuiz)
        } else if let selectedWordCollection = selectedWordCollection {
            return .wordCollection(selectedWordCollection)
        } else if case .discover? = selectedTab, let discoverDetail {
            return .discover(discoverDetail)
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
        switch selectedTab {
        case .myDictionary:
            selectedSharedWord = nil
            selectedIdiom = nil
            selectedQuiz = nil
            selectedWordCollection = nil
            discoverDetail = nil
        case .wordCollections:
            selectedWord = nil
            selectedSharedWord = nil
            selectedIdiom = nil
            selectedQuiz = nil
            discoverDetail = nil
        case .discover:
            selectedWord = nil
            selectedSharedWord = nil
            selectedIdiom = nil
            selectedQuiz = nil
            selectedWordCollection = nil
        case .quizzes:
            selectedWord = nil
            selectedSharedWord = nil
            selectedIdiom = nil
            selectedWordCollection = nil
            discoverDetail = nil
        case .sharedDictionary:
            selectedWord = nil
            selectedIdiom = nil
            selectedQuiz = nil
            selectedWordCollection = nil
            discoverDetail = nil
        default:
            selectedWord = nil
            selectedSharedWord = nil
            selectedIdiom = nil
            selectedQuiz = nil
            selectedWordCollection = nil
            discoverDetail = nil
        }
    }
}

enum SideBarTab: Hashable {
    case myDictionary
    case wordCollections
    case discover
    case quizzes
    case sharedDictionary(SharedDictionary)

    var title: String {
        switch self {
        case .myDictionary: return Loc.Onboarding.myDictionary
        case .wordCollections: return Loc.WordCollections.wordCatalog
        case .discover: return Loc.Discover.title
        case .quizzes: return Loc.Navigation.Tabbar.quizzes
        case .sharedDictionary(let dictionary): return dictionary.name
        }
    }
    
    var systemImage: String {
        switch self {
        case .myDictionary: return "textformat"
        case .wordCollections: return "books.vertical"
        case .discover: return "music.note"
        case .quizzes: return "questionmark.circle"
        case .sharedDictionary: return "person"
        }
    }

    var selectDetailsText: String? {
        switch self {
        case .myDictionary: Loc.Actions.selectWord
        case .wordCollections: Loc.Actions.selectCollection
        case .discover: nil
        case .quizzes: Loc.Actions.selectQuiz
        case .sharedDictionary: Loc.Actions.selectWord
        }
    }

    static let tabs: [SideBarTab] = [.myDictionary, .wordCollections, .discover, .quizzes]
}

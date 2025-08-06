import SwiftUI
import Combine

final class QuizzesViewModel: BaseViewModel {

    enum Input {
        case selectQuiz(Quiz)
        case deselectQuiz
    }

    @Published private(set) var selectedQuiz: Quiz?
    @Published private(set) var words: [CDWord] = []
    @AppStorage(UDKeys.practiceWordCount) var practiceWordCount: Double = 10
    @AppStorage(UDKeys.practiceHardWordsOnly) var showingHardWordsOnly = false

    private let wordsProvider: WordsProvider = .shared
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        switch input {
        case .selectQuiz(let quiz):
            Task { @MainActor in
                selectedQuiz = quiz
            }
        case .deselectQuiz:
            selectedQuiz = nil
        }
    }

    /// Fetches latest data from Core Data
    private func setupBindings() {
        wordsProvider.$words
            .receive(on: DispatchQueue.main)
            .sink { [weak self] words in
                self?.words = words
                // Words loaded successfully
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var filteredWords: [CDWord] {
        if showingHardWordsOnly {
            return words.filter { $0.difficultyLevel == 2 } // needsReview
        }
        return words
    }
    
    var hasHardWords: Bool {
        return words.contains { $0.difficultyLevel == 2 }
    }
}

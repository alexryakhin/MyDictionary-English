import SwiftUI
import Combine

final class DeleteWordsViewModel: ObservableObject {
    @Published var words: [CDWord] = []
    @Published var selectedWordIds: Set<String> = []
    @Published var searchText: String = ""
    @Published var sortingState: SortingCase = .latest {
        didSet {
            sortWords()
        }
    }
    @Published var deletedCount = 0
    
    private let wordsProvider = WordsProvider.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredWords: [CDWord] {
        let filtered = if searchText.isEmpty {
            words
        } else {
            words.filter { word in
                let wordText = word.wordItself?.lowercased() ?? ""
                let definition = word.primaryDefinition?.lowercased() ?? ""
                let searchLowercased = searchText.lowercased()
                
                return wordText.contains(searchLowercased) || definition.contains(searchLowercased)
            }
        }
        
        return sortWords(filtered)
    }
    
    var isAllSelected: Bool {
        !words.isEmpty && selectedWordIds.count == words.count
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        wordsProvider.$words
            .receive(on: RunLoop.main)
            .sink { [weak self] words in
                self?.words = words
                // Clear selection when words change
                self?.selectedWordIds.removeAll()
            }
            .store(in: &cancellables)
    }
    
    private func sortWords(_ wordsToSort: [CDWord]? = nil) -> [CDWord] {
        let wordsToSort = wordsToSort ?? words
        var sortedWords = wordsToSort
        
        switch sortingState {
        case .earliest:
            sortedWords.sort(by: { lhs, rhs in
                (lhs.timestamp ?? Date()) < (rhs.timestamp ?? Date())
            })
        case .latest:
            sortedWords.sort(by: { lhs, rhs in
                (lhs.timestamp ?? Date()) > (rhs.timestamp ?? Date())
            })
        case .alphabetically:
            sortedWords.sort(by: { lhs, rhs in
                (lhs.wordItself ?? "") < (rhs.wordItself ?? "")
            })
        case .partOfSpeech:
            sortedWords.sort(by: { lhs, rhs in
                (lhs.partOfSpeech ?? "") < (rhs.partOfSpeech ?? "")
            })
        @unknown default:
            break
        }
        
        return sortedWords
    }
    
    func loadWords() {
        do {
            try wordsProvider.fetchWords()
        } catch {
            print("Failed to load words: \(error)")
        }
    }
    
    func toggleSelection(for word: CDWord, isSelected: Bool) {
        guard let wordId = word.id?.uuidString else { return }
        
        if isSelected {
            selectedWordIds.insert(wordId)
        } else {
            selectedWordIds.remove(wordId)
        }
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            selectedWordIds.removeAll()
        } else {
            selectedWordIds = Set(words.compactMap { $0.id?.uuidString })
        }
    }
    
    @MainActor
    func deleteSelectedWords() async {
        guard !selectedWordIds.isEmpty else { return }
        
        do {
            try wordsProvider.deleteWords(with: Array(selectedWordIds))
            deletedCount = selectedWordIds.count
            selectedWordIds.removeAll()
            AlertCenter.shared.showAlert(
                with: .info(
                    title: Loc.Settings.wordsDeletedSuccessfully,
                    message: Loc.Settings.wordsDeletedSuccessfullyMessage(deletedCount)
                )
            )
        } catch {
            print("Failed to delete selected words: \(error)")
            // Handle error appropriately
        }
    }
    
    @MainActor
    func deleteAllWords() async {
        do {
            let wordCount = words.count
            try wordsProvider.deleteAllWords()
            deletedCount = wordCount
            selectedWordIds.removeAll()
            AlertCenter.shared.showAlert(
                with: .info(
                    title: Loc.Settings.wordsDeletedSuccessfully,
                    message: Loc.Settings.wordsDeletedSuccessfullyMessage(deletedCount)
                )
            )
        } catch {
            print("Failed to delete all words: \(error)")
            // Handle error appropriately
        }
    }
}

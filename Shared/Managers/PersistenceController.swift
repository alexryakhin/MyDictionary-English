//
//  Persistence.swift
//  Shared
//
//  Created by Alexander Bonney on 10/6/21.
//

import CoreData
import SwiftUI
import Combine


final class PersistenceController: ObservableObject {
    private let container: NSPersistentCloudKitContainer
    var cancellable = Set<AnyCancellable>()
    @Published var words: [Word] = []
    @Published var sortingState: SortingCase = .def
    @Published var filterState: FilterCase = .none
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "My_Dictionary")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print(error.localizedDescription)
            }
        })
        
        // Update data automatically
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didMergeChangesObjectIDsNotification, object: container.viewContext)
            .sink { _ in
                self.fetchWords()
            }
            .store(in: &cancellable)
        fetchWords()
    }
    
    // MARK: - Core Data Managing support
    
    /// Fetches latest data from Core Data
    private func fetchWords() {
        let request = NSFetchRequest<Word>(entityName: "Word")
        do {
            words = try container.viewContext.fetch(request)
            sortWords()
        } catch {
            print("Error fetching cities. \(error.localizedDescription)")
        }
    }

    /// Saves all changes in Core Data
    func save() {
        do {
            try container.viewContext.save()
            fetchWords()
        } catch let error {
            print("Error with saving data to CD. \(error.localizedDescription)")
        }
        objectWillChange.send()
    }
    
    func addNewWord(word: String, definition: String, partOfSpeech: String, phonetic: String?) {
        let newWord = Word(context: container.viewContext)
        newWord.id = UUID()
        newWord.wordItself = word
        newWord.definition = definition
        newWord.partOfSpeech = partOfSpeech
        newWord.phonetic = phonetic
        newWord.timestamp = Date()
        save()
    }
    
    /// Removes given word from Core Data
    func delete(word: Word) {
        container.viewContext.delete(word)
        save()
    }
    
    // MARK: Sorting
    var favoriteWords: [Word] {
        return self.words.filter { $0.isFavorite }
    }
    
    func sortWords() {
        switch sortingState {
        case .def:
            words.sort(by: { word1, word2 in
                word1.timestamp! < word2.timestamp!
            })
        case .name:
            words.sort(by: { word1, word2 in
                word1.wordItself! < word2.wordItself!
            })
        case .partOfSpeech:
            words.sort(by: { word1, word2 in
                word1.partOfSpeech! < word2.partOfSpeech!
            })
        }
    }
}
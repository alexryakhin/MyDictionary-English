import Combine
import SwiftUI

final class MoreViewModel: BaseViewModel {

    enum Input {
        // No navigation inputs needed
    }

    @AppStorage(UDKeys.selectedTTSLanguage) var selectedTTSLanguage: TTSLanguage = .enUS
    @AppStorage(UDKeys.dailyRemindersEnabled) var dailyRemindersEnabled: Bool = false
    @AppStorage(UDKeys.difficultWordsAlertsEnabled) var difficultWordsEnabled: Bool = false
    @AppStorage(UDKeys.practiceWordCount) var practiceWordCount: Double = 10
    @AppStorage(UDKeys.practiceHardWordsOnly) var practiceHardWordsOnly: Bool = false

    @Published var isImporting = false
    @Published var importFileURL: URL?
    @Published var exportWordsUrl: URL?
    @Published var showingTagManagement = false

    private let wordsProvider: WordsProvider
    private let csvManager: CSVManager
    private let notificationService: NotificationService

    private var words: [CDWord] = []
    private var cancellables: Set<AnyCancellable> = []

    override init() {
        self.wordsProvider = ServiceManager.shared.wordsProvider
        self.csvManager = ServiceManager.shared.csvManager
        self.notificationService = ServiceManager.shared.notificationService
        super.init()
        setupBindings()
    }

    func handle(_ input: Input) {
        // No navigation handling needed
    }

    private func setupBindings() {
        wordsProvider.$words
            .receive(on: RunLoop.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var hasHardWords: Bool {
        return words.contains { $0.difficultyLevel == 2 }
    }

    func exportWords() {
        guard !words.isEmpty else { return }
        Task { @MainActor in
            exportWordsUrl = csvManager.exportWordsToCSV(wordModels: words)
        }
    }

    func importWords(from url: URL) {
        do {
            try csvManager.importWordsFromCSV(
                url: url,
                currentWordIds: words.compactMap { $0.id?.uuidString }
            )
        } catch {
            errorReceived(error, displayType: .alert)
        }
    }
    
    func requestNotificationPermission() {
        Task {
            let granted = await ServiceManager.shared.notificationService.requestPermission()
            if granted {
                // Schedule notifications for today
                ServiceManager.shared.notificationService.scheduleNotificationsForToday()
            }
        }
    }
    
    func updateNotificationSettings() {
        // Only request permission and schedule notifications if user enables a toggle
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                let granted = await notificationService.requestPermission()
                if granted {
                    notificationService.scheduleNotificationsForToday()
                } else {
                    // If permission denied, turn off the toggles
                    await MainActor.run {
                        dailyRemindersEnabled = false
                        difficultWordsEnabled = false
                    }
                }
            }
        } else {
            // If both toggles are off, cancel all notifications
            notificationService.cancelAllNotifications()
        }
    }
}

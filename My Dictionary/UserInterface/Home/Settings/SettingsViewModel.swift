import Combine
import SwiftUI

final class SettingsViewModel: BaseViewModel {

    enum Output {
        case showAboutApp
        case showTagManagement
        case showSharedDictionaries
        case showAuthentication
    }

    enum Input {
        // No navigation inputs needed
    }

    var output = PassthroughSubject<Output, Never>()

    @AppStorage(UDKeys.dailyRemindersEnabled) var dailyRemindersEnabled: Bool = false
    @AppStorage(UDKeys.difficultWordsAlertsEnabled) var difficultWordsEnabled: Bool = false
    @AppStorage(UDKeys.showIdiomsTab) var showIdiomsTab: Bool = true
    @AppStorage(UDKeys.selectedEnglishAccent) var selectedEnglishAccent: EnglishAccent = .american

    @Published var isImporting = false
    @Published var importFileURL: URL?
    @Published var exportWordsUrl: URL?
    @Published var showingTagManagement = false
    @Published var showingSharedDictionaries = false

    private let wordsProvider: WordsProvider = .shared
    private let csvManager: CSVManager = .shared
    private let notificationService: NotificationService = .shared

    private var words: [CDWord] = []
    private var cancellables: Set<AnyCancellable> = []

    override init() {
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
        return words.contains { $0.difficultyLevel == .needsReview }
    }

    func exportWords() {
        guard !words.isEmpty else { return }
        
        let subscriptionService = SubscriptionService.shared
        guard subscriptionService.canExportWords(words.count) else {
            errorReceived(
                CoreError.internalError(.exportLimitExceeded),
                displayType: .alert
            )
            return
        }
        
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
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                // Schedule notifications for today
                NotificationService.shared.scheduleNotificationsForToday()
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

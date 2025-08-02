import SwiftUI
import Combine
import StoreKit

final class SettingsViewModel: BaseViewModel {
    
    enum Input {
        case dailyRemindersToggled(Bool)
        case difficultWordsAlertsToggled(Bool)
        case tagManagementTapped
    }
    
    @AppStorage(UDKeys.isShowingRating) var isShowingRating: Bool = true
    @AppStorage(UDKeys.selectedTTSLanguage) var selectedTTSLanguage: TTSLanguage = .enUS
    @AppStorage(UDKeys.dailyRemindersEnabled) var dailyRemindersEnabled: Bool = false
    @AppStorage(UDKeys.difficultWordsAlertsEnabled) var difficultWordsAlertsEnabled: Bool = false
    @AppStorage(UDKeys.practiceWordCount) var practiceWordCount: Double = 10
    @AppStorage(UDKeys.practiceHardWordsOnly) var practiceHardWordsOnly: Bool = false

    @Published var exportWordsUrl: URL?
    @Published var isImporting = false
    @Published var importFileURL: URL?
    @Published var isShowingTagManagement = false

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
        switch input {
        case .dailyRemindersToggled(let enabled):
            Task {
                await handleDailyRemindersToggle(enabled)
            }
        case .difficultWordsAlertsToggled(let enabled):
            Task {
                await handleDifficultWordsAlertsToggle(enabled)
            }
        case .tagManagementTapped:
            isShowingTagManagement = true
        }
    }
    
    private func handleDailyRemindersToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await notificationService.requestPermission()
            if !granted {
                await MainActor.run {
                    dailyRemindersEnabled = false
                    showAlert(withModel: .init(
                        title: "Permission Denied",
                        message: "Please enable notifications in System Preferences to receive daily reminders."
                    ))
                }
                return
            }
            notificationService.scheduleNotificationsForToday()
        } else {
            notificationService.cancelAllNotifications()
        }
    }
    
    private func handleDifficultWordsAlertsToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await notificationService.requestPermission()
            if !granted {
                await MainActor.run {
                    difficultWordsAlertsEnabled = false
                    showAlert(withModel: .init(
                        title: "Permission Denied",
                        message: "Please enable notifications in System Preferences to receive difficult words alerts."
                    ))
                }
                return
            }
            notificationService.scheduleNotificationsForToday()
        } else {
            notificationService.cancelAllNotifications()
        }
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

    func importWords(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorReceived(CoreError.internalError(.cannotAccessSecurityScopedResource), displayType: .alert)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            try csvManager.importWordsFromCSV(
                url: url,
                currentWordIds: words.compactMap { $0.id?.uuidString }
            )
            showAlert(withModel: .init(title: "Import Successful", message: "Words imported successfully"))
        } catch {
            errorReceived(error, displayType: .alert)
        }
    }

    func exportWords() {
        guard !words.isEmpty else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "Words.csv"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Export Words"

        Task { @MainActor in
            let response = await panel.begin()
            let tempURL = csvManager.exportWordsToCSV(wordModels: words)
            guard response == .OK, let url = panel.url, let tempURL else { return }
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw CoreError.internalError(.cannotAccessSecurityScopedResource)
                }
                defer { url.stopAccessingSecurityScopedResource() }

                try FileManager.default.copyItem(at: tempURL, to: url)
                showAlert(withModel: .init(title: "Export Successful", message: "Words exported successfully."))
            } catch {
                errorReceived(error, displayType: .alert)
            }
        }
    }
}

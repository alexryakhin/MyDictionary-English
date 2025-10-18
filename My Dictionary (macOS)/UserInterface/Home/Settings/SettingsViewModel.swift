import Combine
import SwiftUI
import Foundation

final class SettingsViewModel: BaseViewModel {

    enum Input {
    }

    @AppStorage(UDKeys.dailyRemindersEnabled) var dailyRemindersEnabled: Bool = false
    @AppStorage(UDKeys.difficultWordsAlertsEnabled) var difficultWordsEnabled: Bool = false
    @AppStorage(UDKeys.selectedTTSRegion) var selectedTTSRegion: CountryRegion = .unitedStates

    @Published var isImporting = false
    @Published var importFileURL: URL?
    @Published var exportWordsUrl: URL?
    @Published var showingTagManagement = false
    @Published var showingSharedDictionaries = false
    @Published var dailyRemindersTime = UDService.dailyRemindersTime
    @Published var difficultWordsTime = UDService.difficultWordsTime

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
    }

    private func setupBindings() {
        wordsProvider.$words
            .receive(on: RunLoop.main)
            .assign(to: \.words, on: self)
            .store(in: &cancellables)

        $dailyRemindersTime
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] time in
                self?.updateDailyRemindersTime(time)
            }
            .store(in: &cancellables)

        $difficultWordsTime
            .removeDuplicates()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] time in
                self?.updateDifficultWordsTime(time)
            }
            .store(in: &cancellables)
    }

    func exportWords() {
        guard !words.isEmpty else { return }

        let subscriptionService = SubscriptionService.shared
        guard subscriptionService.canExportWords(words.count) else {
            errorReceived(CoreError.internalError(.exportLimitExceeded))
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "MyDictionaryExport.json"
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = Loc.Settings.exportWordsTitle

        Task { @MainActor in
            let response = await panel.begin()
            guard response == .OK, let url = panel.url else { return }
            
            do {
                // Use JSON v2.0 format for export
                let jsonData = try JSONImportExportService.shared.exportVocabulary()
                
                guard url.startAccessingSecurityScopedResource() else {
                    throw CoreError.internalError(.cannotAccessSecurityScopedResource)
                }
                defer { url.stopAccessingSecurityScopedResource() }

                try jsonData.write(to: url)
                showAlert(withModel: .info(
                    title: Loc.Settings.exportSuccessful,
                    message: "Words exported successfully in JSON format."
                ))
            } catch {
                errorReceived(error)
            }
        }
    }

    func importWords(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorReceived(CoreError.internalError(.cannotAccessSecurityScopedResource))
            return
        }
        
        Task {
            do {
                let fileData = try Data(contentsOf: url)
                let fileExtension = url.pathExtension.lowercased()
                
                if fileExtension == "json" {
                    // Import JSON format (supports both v2.0 and legacy)
                    let result = try JSONImportExportService.shared.importVocabulary(from: fileData, overwriteExisting: false)
                    
                    await MainActor.run {
                        showAlert(withModel: .info(
                            title: Loc.Settings.importSuccessful,
                            message: "Imported \(result.importedCount) words from JSON format. Skipped \(result.skippedCount) duplicates."
                        ))
                    }
                } else if fileExtension == "csv" {
                    // Import CSV format (legacy)
                    try csvManager.importWordsFromCSV(
                        url: url,
                        currentWordIds: words.compactMap { $0.id?.uuidString }
                    )
                } else {
                    throw ImportError.invalidFormat
                }
            } catch {
                await MainActor.run {
                    errorReceived(error)
                }
            }
        }
    }

    func requestNotificationPermission() {
        Task {
            let granted = await NotificationService.shared.requestPermission()
            if granted {
                // Schedule notifications
                NotificationService.shared.scheduleNotificationsForSettings()
            }
        }
    }

    func updateNotificationSettings() {
        // Only request permission and schedule notifications if user enables a toggle
        if dailyRemindersEnabled || difficultWordsEnabled {
            Task {
                let granted = await notificationService.requestPermission()
                if granted {
                    notificationService.scheduleNotificationsForSettings()
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

    // MARK: - Manual Sync Methods

    func uploadBackupToGoogle() async throws {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            errorReceived(CoreError.internalError(.authenticationRequired))
            return
        }
        try await DataSyncService.shared.uploadBackupToGoogle(userEmail: userEmail)
    }

    func downloadBackupFromGoogle() async throws {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            errorReceived(CoreError.internalError(.authenticationRequired))
            return
        }
        try await DataSyncService.shared.downloadBackupFromGoogle(userEmail: userEmail)
    }
    
    // MARK: - Data Maintenance Methods
    
    func checkForDuplicates() async {
        do {
            let result = try DataMigrationService.shared.checkForDuplicates()
            
            if result.hasDuplicates {
                showAlert(withModel: .info(
                    title: Loc.Settings.duplicatesFound,
                    message: Loc.Settings.duplicatesFoundMessage(result.totalDuplicateWords, result.totalDuplicateMeanings, result.totalDuplicateTags)
                ))
            } else {
                showAlert(withModel: .info(
                    title: Loc.Settings.noDuplicates,
                    message: Loc.Settings.noDuplicatesMessage
                ))
            }
        } catch {
            errorReceived(error)
        }
    }
    
    func cleanupDuplicates() async {
        do {
            let result = try await DataMigrationService.shared.runDuplicateCleanup()
            
            showAlert(withModel: .info(
                title: Loc.Settings.cleanupCompleted,
                message: Loc.Settings.cleanupCompletedMessage(result.totalChanges, result.deletedWords, result.deletedMeanings, result.deletedTags, result.mergedMeanings, result.mergedTags)
            ))
        } catch {
            errorReceived(error)
        }
    }
    
    func updateDailyRemindersTime(_ newTime: Date) {
        dailyRemindersTime = newTime
        UDService.dailyRemindersTime = newTime
        
        // Reschedule notifications with new time
        if dailyRemindersEnabled {
            notificationService.scheduleNotificationsForSettings()
        }
    }
    
    func updateDifficultWordsTime(_ newTime: Date) {
        difficultWordsTime = newTime
        UDService.difficultWordsTime = newTime
        
        // Reschedule notifications with new time
        if difficultWordsEnabled {
            notificationService.scheduleNotificationsForSettings()
        }
    }
}

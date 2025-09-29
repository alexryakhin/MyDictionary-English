import Combine
import SwiftUI
import Foundation

final class SettingsViewModel: BaseViewModel {

    enum Output {
        case showAboutApp
        case showTagManagement
        case showSharedDictionaries
        case showAuthentication
        case showProfile
    }

    enum Input {
        // No navigation inputs needed
    }

    var output = PassthroughSubject<Output, Never>()

    @AppStorage(UDKeys.dailyRemindersEnabled) var dailyRemindersEnabled: Bool = false
    @AppStorage(UDKeys.difficultWordsAlertsEnabled) var difficultWordsEnabled: Bool = false
    @AppStorage(UDKeys.selectedEnglishAccent) var selectedEnglishAccent: EnglishAccent = .american

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
        // No navigation handling needed
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
            errorReceived(
                CoreError.internalError(.exportLimitExceeded)
            )
            return
        }

        Task { @MainActor in
            // Use JSON v2.0 format for export
            do {
                let jsonData = try JSONImportExportService.shared.exportVocabulary()
                let fileName = "MyDictionaryExport.json"
                let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try jsonData.write(to: filePath)
                exportWordsUrl = filePath
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
                        AlertCenter.shared.showAlert(
                            with: .info(
                                title: Loc.Settings.importSuccessful,
                                message: "Imported \(result.importedCount) words from JSON format. Skipped \(result.skippedCount) duplicates."
                            )
                        )
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
                    // If permission denied, turn off the toggles and show alert
                    await MainActor.run {
                        dailyRemindersEnabled = false
                        difficultWordsEnabled = false

                        // Show alert with options to cancel or open settings
                        AlertCenter.shared.showAlert(
                            with: .choice(
                                title: Loc.Notifications.permissionRequired,
                                message: Loc.Notifications.permissionDeniedMessage,
                                cancelText: Loc.Actions.cancel,
                                primaryText: Loc.Actions.settings,
                                secondaryText: .empty,
                                onCancel: {},
                                onPrimary: {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                            )
                        )
                    }
                }
            }
        } else {
            // If both toggles are off, cancel all notifications
            notificationService.cancelAllNotifications()
        }
    }
    
    func updateDailyRemindersTime(_ newTime: Date) {
        dailyRemindersTime = newTime
        UDService.dailyRemindersTime = newTime
        
        // Reschedule notifications with new time
        if dailyRemindersEnabled {
            Task {
                let granted = await notificationService.requestPermission()
                if granted {
                    notificationService.scheduleNotificationsForToday()
                }
            }
        }
    }
    
    func updateDifficultWordsTime(_ newTime: Date) {
        difficultWordsTime = newTime
        UDService.difficultWordsTime = newTime
        
        // Reschedule notifications with new time
        if difficultWordsEnabled {
            Task {
                let granted = await notificationService.requestPermission()
                if granted {
                    notificationService.scheduleNotificationsForToday()
                }
            }
        }
    }

    // MARK: - Manual Sync Methods

    func uploadBackupToGoogle() async throws {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            errorReceived(DictionaryError.userNotAuthenticated)
            return
        }
        try await DataSyncService.shared.uploadBackupToGoogle(userEmail: userEmail)
    }

    func downloadBackupFromGoogle() async throws {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            errorReceived(DictionaryError.userNotAuthenticated)
            return
        }
        try await DataSyncService.shared.downloadBackupFromGoogle(userEmail: userEmail)
    }
    
    // MARK: - Data Maintenance Methods
    
    func checkForDuplicates() async {
        do {
            let result = try DataMigrationService.shared.checkForDuplicates()
            
            if result.hasDuplicates {
                AlertCenter.shared.showAlert(
                    with: .info(
                        title: Loc.Settings.duplicatesFound,
                        message: Loc.Settings.duplicatesFoundMessage(result.totalDuplicateWords, result.totalDuplicateMeanings, result.totalDuplicateTags)
                    )
                )
            } else {
                AlertCenter.shared.showAlert(
                    with: .info(
                        title: Loc.Settings.noDuplicates,
                        message: Loc.Settings.noDuplicatesMessage
                    )
                )
            }
        } catch {
            errorReceived(error)
        }
    }
    
    func cleanupDuplicates() async {
        do {
            let result = try await DataMigrationService.shared.runDuplicateCleanup()
            
            AlertCenter.shared.showAlert(
                with: .info(
                    title: Loc.Settings.cleanupCompleted,
                    message: Loc.Settings.cleanupCompletedMessage(result.totalChanges, result.deletedWords, result.deletedMeanings, result.deletedTags, result.mergedMeanings, result.mergedTags)
                )
            )
        } catch {
            errorReceived(error)
        }
    }
}

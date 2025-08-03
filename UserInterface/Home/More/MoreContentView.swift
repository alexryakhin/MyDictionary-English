import SwiftUI
import UniformTypeIdentifiers
import StoreKit

struct MoreContentView: View {

    @Environment(\.requestReview) var requestReview

    typealias ViewModel = MoreViewModel

    @ObservedObject var viewModel: ViewModel

    init(viewModel: MoreViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {

            // MARK: - Notifications

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminders")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Get reminded at 8 PM if you haven't opened the app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.dailyRemindersEnabled)
                        .labelsHidden()
                        .onChange(of: viewModel.dailyRemindersEnabled) {
                            viewModel.updateNotificationSettings()
                        }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Difficult Words")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Get reminded at 4 PM to practice difficult words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.difficultWordsEnabled)
                        .labelsHidden()
                        .onChange(of: viewModel.difficultWordsEnabled) {
                            viewModel.updateNotificationSettings()
                        }
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Daily reminders only send if you haven't opened the app that day.")
            }

            // MARK: - Tag Management

            Section {
                Button {
                    viewModel.showingTagManagement = true
                } label: {
                    Label("Manage Tags", systemImage: "tag")
                }
            } header: {
                Text("Organization")
            } footer: {
                Text("Create and manage tags to organize your words.")
            }

            // MARK: - Selected Accent

            Section {
                Picker("Selected Accent", selection: $viewModel.selectedTTSLanguage) {
                    ForEach(TTSLanguage.allCases) { language in
                        Text(language.title)
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Voice over accent")
            }

            // MARK: - Import & Export

            Section {
                Button {
                    viewModel.isImporting = true
                    AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                } label: {
                    Label("Import words", systemImage: "square.and.arrow.down")
                }
                Button {
                    viewModel.exportWords()
                    AnalyticsService.shared.logEvent(.exportToCSVButtonTapped)
                } label: {
                    Label("Export words", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Import / Export")
            } footer: {
                Text("Please note that import and export only work with files created by this app.")
            }

            // MARK: - About app

            Section {
                NavigationLink {
                    AboutAppContentView()
                } label: {
                    Label("About app", systemImage: "info.square")
                }
            } header: {
                Text("About app")
            }
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
        .sheet(item: $viewModel.exportWordsUrl) { url in
            ShareSheet(activityItems: [url])
        }
        .sheet(isPresented: $viewModel.showingTagManagement) {
            TagManagementView()
        }
        .fileImporter(
            isPresented: $viewModel.isImporting,
            allowedContentTypes: [UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importWords(from: url)
                }
            case .failure(let error):
                viewModel.errorReceived(error, displayType: .alert)
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
    }
}

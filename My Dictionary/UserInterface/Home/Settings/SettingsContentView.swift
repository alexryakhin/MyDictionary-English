import SwiftUI
import UniformTypeIdentifiers
import StoreKit
import FirebaseAuth

struct SettingsContentView: View {

    @Environment(\.requestReview) var requestReview
    @ObservedObject private var viewModel: SettingsViewModel
    @AppStorage(UDKeys.translateDefinitions) var translateDefinitions: Bool = false
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingAuthentication = false
    @State private var showingSignOutConfirmation = false

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {

            // MARK: - Translate Definitions
            if !GlobalConstant.isEnglishLanguage {
                Section {
                    Toggle("Show definitions in your native language", isOn: $translateDefinitions)
                } header: {
                    Text("Translate Definitions")
                }
            }

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

            // MARK: - Word Lists & Sync

            Section {
                if authService.isSignedIn {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Signed in as")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(authService.displayName ?? authService.userEmail ?? "Anonymous")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Sign Out") {
                                HapticManager.shared.triggerSelection()
                                showingSignOutConfirmation = true
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showingAuthentication = true
                        } label: {
                            Label("Sign in to sync word lists", systemImage: "person.circle")
                        }
                        
                        Text("Local mode - words saved on this device only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Word Lists & Sync")
            } footer: {
                if authService.isSignedIn {
                    Text("Your word lists are synced across all your devices.")
                } else {
                    Text("Sign in to create and share word lists with others.")
                }
            }

            // MARK: - Tag Management

            Section {
                Button {
                    viewModel.showingTagManagement = true
                } label: {
                    Label("Manage Tags", systemImage: "tag")
                }
                
                if authService.isSignedIn {
                    Button {
                        viewModel.showingSharedDictionaries = true
                    } label: {
                        Label("Shared Dictionaries", systemImage: "person.2")
                    }
                }
            } header: {
                Text("Organization")
            } footer: {
                Text("Create and manage tags to organize your words, and add collaborators to share words with.")
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
        .sheet(isPresented: $viewModel.showingSharedDictionaries) {
            SharedDictionariesListView()
        }
        .sheet(isPresented: $showingAuthentication) {
            AuthenticationView()
        }
        .overlay {
            if showingSignOutConfirmation {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingSignOutConfirmation = false
                        }
                    
                    SignOutAlertView {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: showingSignOutConfirmation)
            }
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

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
            // MARK: - Settings

            Section {
                Picker("Selected Accent", selection: $viewModel.selectedTTSLanguage) {
                    ForEach(TTSLanguage.allCases) { language in
                        Text(language.title)
                            .tag(language)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Settings")
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
        .navigationTitle("More")
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
            AnalyticsService.shared.logEvent(.moreOpened)
        }
    }
}

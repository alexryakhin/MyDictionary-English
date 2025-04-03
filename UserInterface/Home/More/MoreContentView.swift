import SwiftUI
import CoreUserInterface
import Core
import Shared
import UniformTypeIdentifiers
import StoreKit
import Services

public struct MoreContentView: PageView {

    @Environment(\.requestReview) var requestReview

    public typealias ViewModel = MoreViewModel

    @ObservedObject public var viewModel: ViewModel

    public init(viewModel: MoreViewModel) {
        self.viewModel = viewModel
    }

    public var contentView: some View {
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

            // MARK: - About app

            Section {
                Button {
                    viewModel.handle(.showAboutApp)
                } label: {
                    Label("About app", systemImage: "info.square")
                }
            } header: {
                Text("About app")
            }
        }
        .listStyle(.insetGrouped)
        .sheet(item: $viewModel.exportWordsUrl) { url in
            ShareSheet(activityItems: [url])
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

import SwiftUI
import Core
import CoreUserInterface__macOS_
import Shared
import Services
import UniformTypeIdentifiers

struct SettingsView: PageView {
    typealias ViewModel = SettingsViewModel

    @Environment(\.requestReview) var requestReview
    @Environment(\.openWindow) private var openWindow

    var _viewModel = StateObject(wrappedValue: ViewModel())
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    var contentView: some View {
        ScrollView {

            // MARK: - Settings

            Section {
                Menu {
                    ForEach(TTSLanguage.allCases, id: \.self) { language in
                        Button(language.title) {
                            viewModel.selectedTTSLanguage = language
                        }
                    }
                } label: {
                    Label("Selected Accent", systemImage: "globe")
                }
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
                    openWindow(id: WindowID.about)
                } label: {
                    Label("About app", systemImage: "info.square")
                }
            } header: {
                Text("About app")
            }
        }
        .fileImporter(
            isPresented: _viewModel.projectedValue.isImporting,
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
        .frame(width: 350, height: 500)
        .background(Color.backgroundColor)
    }
}

#Preview {
    SettingsView()
}

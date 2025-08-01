import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    typealias ViewModel = SettingsViewModel

    @Environment(\.requestReview) var requestReview
    @Environment(\.openWindow) private var openWindow

    var _viewModel = StateObject(wrappedValue: ViewModel())
    var viewModel: ViewModel {
        _viewModel.wrappedValue
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                settingsSectionView
                importExportSectionView
                aboutSectionView
            }
            .padding(vertical: 12, horizontal: 16)
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
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertModel.title),
                message: Text(viewModel.alertModel.message ?? ""),
                primaryButton: .default(Text(viewModel.alertModel.actionText ?? "OK")) {
                    viewModel.alertModel.action?()
                },
                secondaryButton: viewModel.alertModel.destructiveActionText != nil ? .destructive(Text(viewModel.alertModel.destructiveActionText!)) {
                    viewModel.alertModel.destructiveAction?()
                } : .cancel()
            )
        }
        .frame(width: 400, height: 500)
    }

    // MARK: - Settings
    private var settingsSectionView: some View {
        CustomSectionView(header: "Settings") {
            FormWithDivider {
                CellWrapper {
                    Picker(selection: _viewModel.projectedValue.selectedTTSLanguage) {
                        ForEach(TTSLanguage.allCases) { language in
                            Text(language.title)
                                .tag(language)
                        }
                    } label: {
                        Text("Selected Accent")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .pickerStyle(.menu)
                    .buttonStyle(.borderless)
                }
            }
            .clippedWithBackground(.surfaceColor)
        }
        .onChange(of: viewModel.selectedTTSLanguage) { _ in
            AnalyticsService.shared.logEvent(.languageAccentChanged)
        }
    }

    // MARK: - Import & Export
    private var importExportSectionView: some View {
        CustomSectionView(
            header: "Import / Export",
            footer: "Please note that import and export only work with files created by this app."
        ) {
            FormWithDivider {
                ListButton("Import words", systemImage: "square.and.arrow.down") {
                    viewModel.isImporting = true
                    AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                }
                ListButton("Export words", systemImage: "square.and.arrow.up") {
                    viewModel.exportWords()
                    AnalyticsService.shared.logEvent(.exportToCSVButtonTapped)
                }
            }
            .clippedWithBackground(.surfaceColor)
        }
    }

    // MARK: - About app
    private var aboutSectionView: some View {
        CustomSectionView(header: "About app") {
            ListButton("About app", systemImage: "info.square") {
                openWindow(id: WindowID.about)
                AnalyticsService.shared.logEvent(.aboutAppTapped)
            }
            .clippedWithBackground(.surfaceColor)
        }
    }
}

#Preview {
    SettingsView()
}

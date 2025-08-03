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
                notificationSettingsSectionView
                practiceSettingsSectionView
                translationSettingsSectionView
                tagManagementSectionView
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
        .sheet(isPresented: _viewModel.projectedValue.isShowingTagManagement) {
            TagManagementView()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
        .alert(isPresented: _viewModel.projectedValue.isShowingAlert) {
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
        .frame(width: 400, height: 600)
    }

    // MARK: - Notification Settings
    private var notificationSettingsSectionView: some View {
        CustomSectionView(header: "Notifications") {
            FormWithDivider {
                CellWrapper {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Reminders")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Get reminded to practice daily")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: _viewModel.projectedValue.dailyRemindersEnabled)
                            .labelsHidden()
                            .onChange(of: viewModel.dailyRemindersEnabled) { newValue in
                                viewModel.handle(.dailyRemindersToggled(newValue))
                            }
                    }
                }
                
                CellWrapper {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Difficult Words Alerts")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Get notified about words that need review")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: _viewModel.projectedValue.difficultWordsAlertsEnabled)
                            .labelsHidden()
                            .onChange(of: viewModel.difficultWordsAlertsEnabled) { newValue in
                                viewModel.handle(.difficultWordsAlertsToggled(newValue))
                            }
                    }
                }
            }
            .clippedWithBackground()
        }
    }

    // MARK: - Translation Settings
    private var translationSettingsSectionView: some View {
        // Only show if user's locale is not English
        if !GlobalConstant.isEnglishLanguage {
            CustomSectionView(header: "Translation Settings") {
                CellWrapper {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Translate Definitions")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Show definitions in your native language")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: _viewModel.projectedValue.translateDefinitions)
                            .labelsHidden()
                            .onChange(of: viewModel.translateDefinitions) { newValue in
                                AnalyticsService.shared.logEvent(newValue ? .definitionTranslationEnabled : .definitionTranslationDisabled)
                            }
                    }
                }
                .clippedWithBackground()
            }
        } else {
            EmptyView()
        }
    }

    // MARK: - Practice Settings
    private var practiceSettingsSectionView: some View {
        CustomSectionView(header: "Practice Settings") {
            FormWithDivider {
                CellWrapper {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Words per session")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(viewModel.practiceWordCount))")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .fontWeight(.medium)
                        }
                        
                        Slider(
                            value: _viewModel.projectedValue.practiceWordCount,
                            in: 5...50,
                            step: 5
                        )
                        .accentColor(.blue)
                    }
                }
                
                CellWrapper {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Practice hard words only")
                                .font(.body)
                                .fontWeight(.medium)
                            Text("Focus on words that need review")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: _viewModel.projectedValue.practiceHardWordsOnly)
                            .labelsHidden()
                            .disabled(!viewModel.hasHardWords)
                    }
                }
            }
            .clippedWithBackground()
        }
    }

    // MARK: - Tag Management
    private var tagManagementSectionView: some View {
        CustomSectionView(header: "Tag Management") {
            FormWithDivider {
                ListButton("Manage Tags", systemImage: "tag") {
                    viewModel.handle(.tagManagementTapped)
                    AnalyticsService.shared.logEvent(.tagManagementOpened)
                }
            }
            .clippedWithBackground()
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
            .clippedWithBackground()
        }
    }

    // MARK: - About app
    private var aboutSectionView: some View {
        CustomSectionView(header: "About app") {
            ListButton("About app", systemImage: "info.square") {
                openWindow(id: WindowID.about)
                AnalyticsService.shared.logEvent(.aboutAppTapped)
            }
            .clippedWithBackground()
        }
    }
}

#Preview {
    SettingsView()
}

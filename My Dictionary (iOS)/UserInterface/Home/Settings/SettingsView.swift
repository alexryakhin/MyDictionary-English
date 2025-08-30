//
//  SettingsView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/9/25.
//

import SwiftUI
import UniformTypeIdentifiers
import StoreKit
import FirebaseAuth

struct SettingsView: View {

    @Environment(\.requestReview) var requestReview
    @ObservedObject var viewModel: SettingsViewModel
    @AppStorage(UDKeys.translateDefinitions) var translateDefinitions: Bool = true
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var dataSyncService = DataSyncService.shared
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @State private var showingTTSVoiceSelection: Bool = false

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                translateDefinitionsSection
                ttsSection

                // MARK: - Notifications

                CustomSectionView(
                    header: Loc.Settings.notifications,
                    footer: Loc.Settings.dailyRemindersDescription
                ) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Loc.Settings.dailyReminders)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.dailyRemindersDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.dailyRemindersEnabled)
                                .labelsHidden()
                                .onChange(of: viewModel.dailyRemindersEnabled) {
                                    viewModel.updateNotificationSettings()
                                }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Loc.Settings.difficultWords)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.difficultWordsDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.difficultWordsEnabled)
                                .labelsHidden()
                                .onChange(of: viewModel.difficultWordsEnabled) {
                                    viewModel.updateNotificationSettings()
                                }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - Subscription

                CustomSectionView(
                    header: Loc.Settings.subscription,
                    footer: Loc.Settings.proUpgradeDescription
                ) {
                    SubscriptionStatusView()
                }

                // MARK: - Registration Prompt for Anonymous Pro Users

                if subscriptionService.isProUser && !authenticationService.isSignedIn {
                    CustomSectionView(
                        header: Loc.Auth.accountRegistration,
                        footer: Loc.Auth.registerForCrossPlatformAccess
                    ) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Loc.Auth.activeSubscriptionNotification)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text(Loc.Auth.registerToUnlockCrossPlatform)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            ActionButton(
                                Loc.Auth.registerNow,
                                systemImage: "person.crop.circle.badge.plus",
                                style: .borderedProminent
                            ) {
                                viewModel.output.send(.showAuthentication)
                            }
                        }
                        .padding(16)
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                    }
                }

                // MARK: - Word Lists & Sync

                CustomSectionView(
                    header: Loc.Settings.wordListsAndSync,
                    footer: authenticationService.isSignedIn
                    ? Loc.Settings.manualSyncModeDescription
                    : Loc.Settings.signInToCreateShareWordLists
                ) {
                    if authenticationService.isSignedIn {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.accent)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Loc.Settings.signedInAs)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(authenticationService.displayName ?? authenticationService.userEmail ?? Loc.Settings.anonymous)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(vertical: 12, horizontal: 16)
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                            .onTap {
                                HapticManager.shared.triggerSelection()
                                viewModel.output.send(.showProfile)
                            }

                            // Manual sync buttons
                            AsyncActionButton(
                                Loc.Settings.uploadBackupToGoogle,
                                systemImage: "icloud.and.arrow.up"
                            ) {
                                try await viewModel.uploadBackupToGoogle()
                            }

                            AsyncActionButton(
                                Loc.Settings.downloadBackupFromGoogle,
                                systemImage: "icloud.and.arrow.down"
                            ) {
                                try await viewModel.downloadBackupFromGoogle()
                            }
                        }
                        .padding(.bottom, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ActionButton(Loc.Settings.signInToSyncWordLists, systemImage: "person.circle") {
                                viewModel.output.send(.showAuthentication)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }

                // MARK: - Tag Management

                CustomSectionView(
                    header: Loc.Settings.organization,
                    footer: Loc.Settings.tagManagementDescription
                ) {
                    VStack(spacing: 8) {
                        ActionButton(Loc.Tags.manageTags, systemImage: "tag") {
                            viewModel.output.send(.showTagManagement)
                        }

                        if authenticationService.isSignedIn {
                            ActionButton(Loc.Settings.sharedDictionaries, systemImage: "person.2") {
                                viewModel.output.send(.showSharedDictionaries)
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - Import & Export

                CustomSectionView(
                    header: Loc.Settings.importExport,
                    footer: Loc.Settings.importExportNote
                ) {
                    VStack(spacing: 8) {
                        let wordsCount = WordsProvider.shared.words.count
                        ActionButton(Loc.Settings.importWords, systemImage: "square.and.arrow.down") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.isImporting = true
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                        }
                        ActionButton(Loc.Settings.exportWords, systemImage: "square.and.arrow.up") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.exportWords()
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.exportToCSVButtonTapped)
                        }

                        if !subscriptionService.isProUser {
                            Text(Loc.Settings.freeUsersExportLimit(AppConfig.Features.freeUserExportLimit))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - Data Maintenance

                CustomSectionView(
                    header: Loc.Settings.dataMaintenance,
                    footer: Loc.Settings.dataMaintenanceDescription
                ) {
                    VStack(spacing: 8) {
                        AsyncActionButton(
                            Loc.Settings.checkForDuplicates,
                            systemImage: "magnifyingglass"
                        ) {
                            await viewModel.checkForDuplicates()
                        }
                        
                        AsyncActionButton(
                            Loc.Settings.cleanUpDuplicates,
                            systemImage: "trash"
                        ) {
                            await viewModel.cleanupDuplicates()
                        }
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - About app

                CustomSectionView(
                    header: Loc.Settings.aboutApp
                ) {
                    ActionButton(Loc.Settings.learnMore, systemImage: "info.circle") {
                        viewModel.output.send(.showAboutApp)
                    }
                }
            }
            .padding(.horizontal, 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .multilineTextAlignment(.leading)
        .navigation(title: Loc.Navigation.Tabbar.settings, mode: .large)
        .fileImporter(
            isPresented: $viewModel.isImporting,
            allowedContentTypes: [UTType.commaSeparatedText, UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importWords(from: url)
                }
            case .failure(let error):
                viewModel.errorReceived(error)
            }
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
        .sheet(item: $viewModel.exportWordsUrl) { url in
            ShareSheet(activityItems: [url])
        }
    }

    // MARK: - Translate Definitions Section

    @ViewBuilder
    private var translateDefinitionsSection: some View {
        if !GlobalConstant.isEnglishLanguage {
            CustomSectionView(header: Loc.Settings.translateDefinitions) {
                Toggle(Loc.Settings.showDefinitionsNativeLanguage, isOn: $translateDefinitions)
            }
        }
    }

    // MARK: - TTS Section

    private var ttsSection: some View {
        CustomSectionView(header: Loc.Tts.Settings.textToSpeech) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(.speechifyLogo)
                        .foregroundStyle(.accent)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.Tts.Settings.speechify)
                            .font(.headline)

                        Text(
                            subscriptionService.isProUser
                            ? Loc.Tts.Settings.speechifyProDescription
                            : Loc.Tts.Settings.speechifyDescription
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                HStack(spacing: 8) {
                    Image(systemName: "person.wave.2.fill")
                        .foregroundStyle(.accent)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.Tts.currentVoice)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if subscriptionService.isProUser, let currentVoice = ttsPlayer.selectedSpeechifyVoiceModel {
                            Text([currentVoice.name, currentVoice.languageDisplayName].joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(Loc.Tts.defaultVoice)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                if !subscriptionService.isProUser && GlobalConstant.isEnglishLanguage {
                    HStack(spacing: 8) {
                        Text(Loc.Settings.selectAccent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HeaderButtonMenu(viewModel.selectedEnglishAccent.displayName, size: .small) {
                            Picker(
                                Loc.Settings.selectAccent,
                                selection: $viewModel.selectedEnglishAccent
                            ) {
                                ForEach(EnglishAccent.allCases, id: \.self) {
                                    Text($0.displayName).tag($0)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                }
            }
        } trailingContent: {
            if subscriptionService.isProUser {
                HeaderButton(
                    Loc.Tts.dashboard,
                    size: .small
                ) {
                    NavigationManager.shared.navigate(to: .ttsDashboard)
                }
            } else {
                HeaderButton(
                    Loc.Tts.Filters.selectVoice,
                    size: .small
                ) {
                    showingTTSVoiceSelection = true
                }
            }
        }
        .sheet(isPresented: $showingTTSVoiceSelection) {
            VoicePickerView()
        }
    }
}

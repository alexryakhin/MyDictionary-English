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

    @Environment(\.dismiss) var dismiss
    @Environment(\.openWindow) var openWindow
    @Environment(\.requestReview) var requestReview

    @AppStorage(UDKeys.translateDefinitions) var translateDefinitions: Bool = false

    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var dataSyncService = DataSyncService.shared
    @StateObject private var ttsPlayer = TTSPlayer.shared

    @State private var showingSignIn: Bool = false
    @State private var showingTagManagement: Bool = false
    @State private var showingSharedDictionaries: Bool = false
    @State private var showingProfile: Bool = false
    @State private var showingTTSDashboard: Bool = false
    @State private var showingTTSVoiceSelection: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                translateDefinitionsSection
                ttsSection

                // MARK: - Notifications

                CustomSectionView(
                    header: Loc.Settings.notifications.localized,
                    footer: Loc.Settings.dailyRemindersDescription.localized
                ) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Loc.Settings.dailyReminders.localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.dailyRemindersDescription.localized)
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
                                Text(Loc.Settings.difficultWords.localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.difficultWordsDescription.localized)
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
                    header: Loc.Settings.subscription.localized,
                    footer: Loc.Settings.proUpgradeDescription.localized
                ) {
                    SubscriptionStatusView()
                }

                // MARK: - Registration Prompt for Anonymous Pro Users

                if subscriptionService.isProUser && !authenticationService.isSignedIn {
                    CustomSectionView(
                        header: Loc.Auth.accountRegistration.localized,
                        footer: Loc.Auth.registerForCrossPlatformAccess.localized
                    ) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Loc.Auth.activeSubscriptionNotification.localized)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text(Loc.Auth.registerToUnlockCrossPlatform.localized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }

                            ActionButton(
                                Loc.Auth.registerNow.localized,
                                systemImage: "person.crop.circle.badge.plus",
                                style: .borderedProminent
                            ) {
                                showingSignIn = true
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
                    header: Loc.Settings.wordListsAndSync.localized,
                    footer: authenticationService.isSignedIn
                    ? Loc.Settings.manualSyncModeDescription.localized
                    : Loc.Settings.signInToCreateShareWordLists.localized
                ) {
                    if authenticationService.isSignedIn {
                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    showingProfile = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(Loc.Settings.signedInAs.localized)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)
                                            Text(authenticationService.displayName ?? authenticationService.userEmail ?? Loc.Settings.anonymous.localized)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(vertical: 12, horizontal: 16)
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                            // Manual sync buttons
                            AsyncActionButton(
                                Loc.Settings.uploadBackupToGoogle.localized,
                                systemImage: "icloud.and.arrow.up"
                            ) {
                                try await viewModel.uploadBackupToGoogle()
                            }

                            AsyncActionButton(
                                Loc.Settings.downloadBackupFromGoogle.localized,
                                systemImage: "icloud.and.arrow.down"
                            ) {
                                try await viewModel.downloadBackupFromGoogle()
                            }
                        }
                        .padding(.bottom, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ActionButton(Loc.Settings.signInToSyncWordLists.localized, systemImage: "person.circle") {
                                showingSignIn = true
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }

                // MARK: - Tag Management

                CustomSectionView(
                    header: Loc.Settings.organization.localized,
                    footer: Loc.Settings.tagManagementDescription.localized
                ) {
                    VStack(spacing: 8) {
                        ActionButton(Loc.Tags.manageTags.localized, systemImage: "tag") {
                            showingTagManagement = true
                        }

                        if authenticationService.isSignedIn {
                            ActionButton(Loc.Settings.sharedDictionaries.localized, systemImage: "person.2") {
                                showingSharedDictionaries = true
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - Import & Export

                CustomSectionView(
                    header: Loc.Settings.importExport.localized,
                    footer: Loc.Settings.importExportNote.localized
                ) {
                    VStack(spacing: 8) {
                        let wordsCount = WordsProvider.shared.words.count
                        ActionButton(Loc.Settings.importWords.localized, systemImage: "square.and.arrow.down") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.isImporting = true
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                        }
                        ActionButton(Loc.Settings.exportWords.localized, systemImage: "square.and.arrow.up") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.exportWords()
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.exportToCSVButtonTapped)
                        }

                        if !subscriptionService.isProUser {
                            Text(Loc.Settings.freeUsersExportLimit.localized(AppConfig.Features.freeUserExportLimit))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - About app

                CustomSectionView(
                    header: Loc.Settings.aboutApp.localized
                ) {
                    ActionButton(Loc.Settings.learnMore.localized, systemImage: "info.circle") {
                        openWindow(id: WindowID.about)
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .multilineTextAlignment(.leading)
        .navigationTitle(Loc.TabBar.settings.localized)
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
                viewModel.errorReceived(error)
            }
        }
        .sheet(isPresented: $showingSignIn) {
            AuthenticationView()
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
        }
        .sheet(isPresented: $showingSharedDictionaries) {
            SharedDictionariesListView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
        .onReceive(authenticationService.$authenticationState) { state in
            if state == .signedOut {
                showingProfile = false
            }
        }
    }

    // MARK: - Translate Definitions Section

    @ViewBuilder
    private var translateDefinitionsSection: some View {
        if !GlobalConstant.isEnglishLanguage {
            CustomSectionView(header: Loc.Settings.translateDefinitions.localized) {
                HStack {
                    Text(Loc.Settings.showDefinitionsNativeLanguage.localized)
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Toggle(Loc.Settings.showDefinitionsNativeLanguage.localized, isOn: $translateDefinitions)
                        .labelsHidden()
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
            }
        }
    }

    // MARK: - TTS Section

    private var ttsSection: some View {
        CustomSectionView(header: Loc.TTS.textToSpeech.localized) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(.speechifyLogo)
                        .foregroundStyle(.accent)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.TTS.speechify.localized)
                            .font(.headline)

                        Text(
                            subscriptionService.isProUser
                            ? Loc.TTS.speechifyProDescription.localized
                            : Loc.TTS.speechifyDescription.localized
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
                        Text(Loc.TTS.currentVoice.localized)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if subscriptionService.isProUser, let currentVoice = ttsPlayer.selectedSpeechifyVoiceModel {
                            Text([currentVoice.name, currentVoice.languageDisplayName].joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(Loc.TTS.defaultVoice.localized)
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
                        Text(Loc.Settings.selectAccent.localized)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HeaderButtonMenu(viewModel.selectedEnglishAccent.displayName, size: .small) {
                            Picker(
                                Loc.Settings.selectAccent.localized,
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
                    Loc.TTS.dashboard.localized,
                    size: .small
                ) {
                    showingTTSDashboard = true
                }
            } else {
                HeaderButton(
                    Loc.TTS.selectVoice.localized,
                    size: .small
                ) {
                    showingTTSVoiceSelection = true
                }
            }
        }
        .sheet(isPresented: $showingTTSDashboard) {
            TTSDashboard.ContentView()
        }
        .sheet(isPresented: $showingTTSVoiceSelection) {
            VoicePickerView()
        }
    }
}

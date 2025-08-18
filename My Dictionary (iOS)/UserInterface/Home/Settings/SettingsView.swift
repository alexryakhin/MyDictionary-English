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
    @AppStorage(UDKeys.translateDefinitions) var translateDefinitions: Bool = false
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var dataSyncService = DataSyncService.shared

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Translate Definitions
                if !GlobalConstant.isEnglishLanguage {
                    CustomSectionView(header: Loc.Settings.translateDefinitions.localized) {
                        Toggle(Loc.Settings.showDefinitionsNativeLanguage.localized, isOn: $translateDefinitions)
                    }
                } else {
                    CustomSectionView(header: Loc.Settings.accent.localized) {
                        HStack {
                            Text(Loc.Settings.selectAccent.localized)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HeaderButtonMenu(viewModel.selectedEnglishAccent.displayName, size: .small) {
                                Picker(Loc.Settings.selectAccent.localized, selection: $viewModel.selectedEnglishAccent) {
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
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(Loc.Settings.signedInAs.localized)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(authenticationService.displayName ?? authenticationService.userEmail ?? Loc.Settings.anonymous.localized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()

                                    HeaderButton(Loc.Settings.signOut.localized, color: .red, size: .small) {
                                        HapticManager.shared.triggerSelection()
                                        authenticationService.toggleSignOutView()
                                    }
                                }
                            }
                            .padding(vertical: 12, horizontal: 16)
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                            // Manual sync buttons
                            ActionButton(
                                Loc.Settings.uploadBackupToGoogle.localized,
                                systemImage: "icloud.and.arrow.up",
                                isLoading: dataSyncService.isUploading
                            ) {
                                viewModel.uploadBackupToGoogle()
                            }

                            ActionButton(
                                Loc.Settings.downloadBackupFromGoogle.localized,
                                systemImage: "icloud.and.arrow.down",
                                isLoading: dataSyncService.isRestoring
                            ) {
                                viewModel.downloadBackupFromGoogle()
                            }
                        }
                        .padding(.bottom, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ActionButton(Loc.Settings.signInToSyncWordLists.localized, systemImage: "person.circle") {
                                viewModel.output.send(.showAuthentication)
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
                        HStack {
                            Text(Loc.Settings.showIdiomsTab.localized)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Toggle(Loc.Settings.showIdiomsTab.localized, isOn: $viewModel.showIdiomsTab)
                                .labelsHidden()
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                        ActionButton(Loc.Tags.manageTags.localized, systemImage: "tag") {
                            viewModel.output.send(.showTagManagement)
                        }

                        if authenticationService.isSignedIn {
                            ActionButton(Loc.Settings.sharedDictionaries.localized, systemImage: "person.2") {
                                viewModel.output.send(.showSharedDictionaries)
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
        .navigation(title: Loc.TabBar.settings.localized, mode: .large)
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
        .onAppear {
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
        #if os(iOS)
        .sheet(item: $viewModel.exportWordsUrl) { url in
            ShareSheet(activityItems: [url])
        }
        #endif
    }
}

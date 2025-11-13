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

    @AppStorage(UDKeys.appleMusicAuthorized) private var appleMusicAuthorized: Bool = false
    @StateObject private var authenticationService = AuthenticationService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var paywallService = PaywallService.shared
    @StateObject private var dataSyncService = DataSyncService.shared
    @StateObject private var ttsPlayer = TTSPlayer.shared
    @State private var showingTTSVoiceSelection: Bool = false
    @State private var showLearningPreferences: Bool = false

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ttsSection
                    .hideIfOffline()

                // MARK: - Notifications

                CustomSectionView(header: Loc.Settings.notifications) {
                    VStack(spacing: 8) {
                        // Word Study Notifications (first in stack)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Loc.Settings.wordStudyReminders)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.wordStudyRemindersDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.wordStudyNotificationsEnabled)
                                .labelsHidden()
                                .onChange(of: viewModel.wordStudyNotificationsEnabled) {
                                    viewModel.updateNotificationSettings()
                                }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Loc.Settings.dailyReminders)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.dailyRemindersDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                DatePicker(
                                    "",
                                    selection: $viewModel.dailyRemindersTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.dailyRemindersEnabled)
                                .labelsHidden()
                                .onChange(of: viewModel.dailyRemindersEnabled) {
                                    viewModel.updateNotificationSettings()
                                }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Loc.Settings.difficultWords)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(Loc.Settings.difficultWordsDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                DatePicker(
                                    "",
                                    selection: $viewModel.difficultWordsTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.difficultWordsEnabled)
                                .labelsHidden()
                                .onChange(of: viewModel.difficultWordsEnabled) {
                                    viewModel.updateNotificationSettings()
                                }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                    }
                }

                // MARK: - Subscription

                CustomSectionView(
                    header: Loc.Settings.subscription,
                    footer: Loc.Settings.proUpgradeDescription
                ) {
                    SubscriptionStatusView()
                }

                // MARK: - Word Lists & Sync

                CustomSectionView(
                    header: Loc.Settings.wordListsAndSync,
                    footer: authenticationService.isSignedIn
                    ? Loc.Settings.manualSyncModeDescription
                    : Loc.Settings.signInToCreateShareWordLists
                ) {
                    VStack(spacing: 8) {
                        if authenticationService.isSignedIn {
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
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                            .onTap {
                                HapticManager.shared.triggerSelection()
                                viewModel.output.send(.showProfile)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                ActionButton(Loc.Settings.signInToSyncWordLists, systemImage: "person.circle") {
                                    viewModel.output.send(.showAuthentication)
                                }
                                
                                ActionButton(
                                    Loc.Profile.learningPreferencesTitle,
                                    systemImage: "person.crop.circle.badge.ellipsis.fill"
                                ) {
                                    showLearningPreferences.toggle()
                                }
                            }
                        }
                        
                        // Music Services Sign Out
                        musicServicesSignOutSection
                    }
                    .padding(.bottom, 12)
                }
                .hideIfOffline()

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
                            .hideIfOffline()
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
                                paywallService.presentPaywall(for: .unlimitedExport)
                            }
                            AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                        }
                        ActionButton(Loc.Settings.exportWords, systemImage: "square.and.arrow.up") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.exportWords()
                            } else {
                                paywallService.presentPaywall(for: .unlimitedExport)
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
                        
                        ActionButton(
                            Loc.Settings.deleteWords,
                            systemImage: "trash.circle"
                        ) {
                            viewModel.showDeleteWords()
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
            .padding(vertical: 12, horizontal: 16)
            .if(isPad) { view in
                view
                    .frame(maxWidth: 550, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .groupedBackground()
        .multilineTextAlignment(.leading)
        .navigation(
            title: Loc.Navigation.Tabbar.settings,
            trailingContent: {
                HeaderButton(
                    Loc.Navigation.about,
                    style: .borderedProminent
                ) {
                    viewModel.output.send(.showAboutApp)
                }
            }
        )
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
        .sheet(isPresented: $showLearningPreferences) {
            LearningPreferencesView()
        }
    }
    
    // MARK: - Music Services Sign Out Section
    
    private var musicServicesSignOutSection: some View {
        VStack(spacing: 8) {
            if appleMusicAuthorized {
                AsyncActionButton(
                    "Sign Out from Apple Music",
                    systemImage: "music.note"
                ) {
                    await viewModel.signOutFromAppleMusic()
                }
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
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))

                HStack(spacing: 8) {
                    Image(systemName: "person.wave.2.fill")
                        .foregroundStyle(.accent)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.Tts.currentVoice)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if subscriptionService.isProUser, ttsPlayer.selectedTTSProvider == .speechify, let currentVoice = ttsPlayer.selectedSpeechifyVoiceModel {
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
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))

                if ttsPlayer.selectedTTSProvider == .google || !subscriptionService.isProUser {
                    HStack(spacing: 8) {
                        Text(Loc.Settings.selectAccent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HeaderButtonMenu("\(viewModel.selectedTTSRegion.flagEmoji) \(viewModel.selectedTTSRegion.displayName)", size: .small) {
                            Picker(
                                Loc.Settings.selectAccent,
                                selection: $viewModel.selectedTTSRegion
                            ) {
                                ForEach(CountryRegion.allCasesSorted, id: \.self) { region in
                                    Text("\(region.flagEmoji) \(region.displayName)").tag(region)
                                }
                            }
                            .pickerStyle(.inline)
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
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

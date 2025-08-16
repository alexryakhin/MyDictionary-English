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

    @State private var showingSignIn: Bool = false
    @State private var showingTagManagement: Bool = false
    @State private var showingSharedDictionaries: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // MARK: - Translate Definitions
                if !GlobalConstant.isEnglishLanguage {
                    CustomSectionView(header: "Translate Definitions") {
                        Toggle("Show definitions in your native language", isOn: $translateDefinitions)
                            .padding(vertical: 12, horizontal: 16)
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                    }
                } else {
                    CustomSectionView(header: "Accent") {
                        HStack {
                            Text("Select accent")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HeaderButtonMenu(viewModel.selectedEnglishAccent.displayName, size: .small) {
                                Picker("Select accent", selection: $viewModel.selectedEnglishAccent) {
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
                    header: "Notifications",
                    footer: "Daily reminders only send if you haven't opened the app that day."
                ) {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Reminders")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Get reminded at 8 PM if you haven't opened the app")
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
                                Text("Difficult Words")
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Get reminded at 4 PM to practice difficult words")
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
                    header: "Subscription",
                    footer: "Upgrade to Pro for unlimited features and cross-device sync."
                ) {
                    SubscriptionStatusView()
                }
                
                // MARK: - Word Lists & Sync

                CustomSectionView(
                    header: "Word Lists & Sync",
                    footer: authenticationService.isSignedIn
                    ? "Manual sync mode: Use buttons below to upload/download your word lists to Google. Available to all users."
                    : "Sign in to create and share word lists with others."
                ) {
                    if authenticationService.isSignedIn {
                        VStack(spacing: 8) {

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Signed in as")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(authenticationService.displayName ?? authenticationService.userEmail ?? "Anonymous")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    HeaderButton("Sign Out", color: .red, size: .small) {
                                        authenticationService.toggleSignOutView()
                                    }
                                }
                            }
                            .padding(vertical: 12, horizontal: 16)
                            .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                            
                            // Manual sync buttons
                            ActionButton(
                                "Upload backup to Google",
                                systemImage: "icloud.and.arrow.up",
                                isLoading: dataSyncService.isUploading
                            ) {
                                viewModel.uploadBackupToGoogle()
                            }

                            ActionButton(
                                "Download backup from Google",
                                systemImage: "icloud.and.arrow.down",
                                isLoading: dataSyncService.isRestoring
                            ) {
                                viewModel.downloadBackupFromGoogle()
                            }
                        }
                        .padding(.bottom, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ActionButton("Sign in to sync word lists", systemImage: "person.circle") {
                                showingSignIn = true
                            }
                        }
                        .padding(.bottom, 12)
                    }
                }

                // MARK: - Tag Management

                CustomSectionView(
                    header: "Organization",
                    footer: "Create and manage tags to organize your words, and add collaborators to share words with."
                ) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Show Idioms Tab")
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Toggle("Show Idioms Tab", isOn: $viewModel.showIdiomsTab)
                                .labelsHidden()
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                        ActionButton("Manage Tags", systemImage: "tag") {
                            showingTagManagement = true
                        }

                        if authenticationService.isSignedIn {
                            ActionButton("Shared Dictionaries", systemImage: "person.2") {
                                showingSharedDictionaries = true
                            }
                        }
                    }
                    .padding(.bottom, 12)
                }

                // MARK: - Import & Export

                CustomSectionView(
                    header: "Import / Export",
                    footer: "Please note that import and export only work with files created by this app."
                ) {
                    VStack(spacing: 8) {
                        let wordsCount = WordsProvider.shared.words.count
                        ActionButton("Import words", systemImage: "square.and.arrow.down") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.isImporting = true
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                        }
                        ActionButton("Export words", systemImage: "square.and.arrow.up") {
                            if subscriptionService.isProUser || wordsCount < 50 {
                                viewModel.exportWords()
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.exportToCSVButtonTapped)
                        }
                        
                        if !subscriptionService.isProUser {
                            Text("Free users can export up to \(AppConfig.Features.freeUserExportLimit) words")
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
                    header: "About app"
                ) {
                    ActionButton("Learn more", systemImage: "info.circle") {
                        openWindow(id: WindowID.about)
                    }
                }
            }
            .padding(12)
        }
        .groupedBackground()
        .multilineTextAlignment(.leading)
        .navigationTitle("Settings")
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
        .sheet(isPresented: $authenticationService.showingSignOutView) {
            SignOutView()
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementView()
        }
        .sheet(isPresented: $showingSharedDictionaries) {
            SharedDictionariesListView()
        }
        .onAppear {
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
    }
}

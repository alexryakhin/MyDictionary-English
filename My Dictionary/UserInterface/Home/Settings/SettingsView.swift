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

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Translate Definitions
                if !GlobalConstant.isEnglishLanguage {
                    CustomSectionView(header: "Translate Definitions") {
                        Toggle("Show definitions in your native language", isOn: $translateDefinitions)
                    }
                } else {
                    CustomSectionView(header: "Accent") {
                        HStack {
                            Text("Select accent")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Picker("Select accent", selection: $viewModel.selectedEnglishAccent) {
                                ForEach(EnglishAccent.allCases, id: \.self) {
                                    Text($0.displayName).tag($0)
                                }
                            }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 16)
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
                        .clippedWithBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 16)

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
                        .clippedWithBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 16)
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
                    ? "Your word lists are synced across all your devices."
                    : "Sign in to create and share word lists with others."
                ) {
                    if authenticationService.isSignedIn {
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

                                HeaderButton(text: "Sign Out", font: .caption) {
                                    HapticManager.shared.triggerSelection()
                                    authenticationService.toggleSignOutView()
                                }
                                .tint(.red)
                            }
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 16)
                        .padding(.bottom, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                viewModel.output.send(.showAuthentication)
                            } label: {
                                Label("Sign in to sync word lists", systemImage: "person.circle")
                                    .padding(6)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        .clippedWithBackground(Color(.tertiarySystemGroupedBackground), cornerRadius: 16)

                        Button {
                            viewModel.output.send(.showTagManagement)
                        } label: {
                            Label("Manage Tags", systemImage: "tag")
                                .padding(6)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if authenticationService.isSignedIn {
                            Button {
                                viewModel.output.send(.showSharedDictionaries)
                            } label: {
                                Label("Shared Dictionaries", systemImage: "person.2")
                                    .padding(6)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                        Button {
                            if subscriptionService.isProUser {
                                viewModel.isImporting = true
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.importFromCSVButtonTapped)
                        } label: {
                            Label("Import words", systemImage: "square.and.arrow.down")
                                .padding(6)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        Button {
                            if subscriptionService.isProUser {
                                viewModel.exportWords()
                            } else {
                                paywallService.isShowingPaywall = true
                            }
                            AnalyticsService.shared.logEvent(.exportToCSVButtonTapped)
                        } label: {
                            Label("Export words", systemImage: "square.and.arrow.up")
                                .padding(6)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
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
                    Button {
                        viewModel.output.send(.showAboutApp)
                    } label: {
                        Label("Learn more", systemImage: "info.circle")
                            .padding(6)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 16)
        }
        .groupedBackground()
        .multilineTextAlignment(.leading)
        .navigation(title: "Settings", mode: .large)
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
            AnalyticsService.shared.logEvent(.settingsOpened)
        }
    }
}

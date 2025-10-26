//
//  ProfileView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

struct ProfileView: View {
    @StateObject private var authenticationService = AuthenticationService.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignOutAlert = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var nameErrorMessage: String?
    @State private var isEditingNickname = false
    @State private var editedNickname = ""
    @State private var nicknameErrorMessage: String?
    @State private var showingLearningPreferences = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader

                // Account Information
                accountInformationSection

                // Nickname Section
                nicknameSection

                // Learning Preferences Section
                learningPreferencesSection

                // Account Linking Section
                accountLinkingSection

                // Sign Out Section
                signOutSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .groupedBackground()
        .navigation(
            title: Loc.Profile.profile,
            mode: .large,
            showsBackButton: true
        )
        .overlay {
            SignOutView()
        }
        .sheet(isPresented: $showingLearningPreferences) {
            LearningPreferencesView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            VStack(spacing: 4) {
                if isEditingName {
                    // Inline editing
                    VStack(spacing: 8) {
                        TextField(Loc.Profile.enterName, text: $editedName)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .onSubmit {
                                Task {
                                    await saveName()
                                }
                            }

                        if let errorMessage = nameErrorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        HStack(spacing: 12) {
                            HeaderButton(Loc.Actions.cancel) {
                                cancelNameEdit()
                            }

                            AsyncHeaderButton(Loc.Actions.save, style: .borderedProminent) {
                                await saveName()
                            }
                            .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                } else {
                    // Display mode
                    HStack {
                        Text(authenticationService.displayName ?? Loc.Settings.anonymous)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Button {
                            startNameEdit()
                        } label: {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                if let email = authenticationService.userEmail {
                    Text(email)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Account Information Section

    private var accountInformationSection: some View {
        CustomSectionView(
            header: Loc.Profile.currentAccount,
        ) {
            VStack(spacing: 12) {
                // Current sign-in method
                HStack {
                    Image(systemName: authenticationService.hasAppleAccount ? "applelogo" : "globe")
                        .foregroundStyle(.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authenticationService.hasAppleAccount ? Loc.Profile.appleId : Loc.Profile.googleAccount)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(Loc.Profile.currentAccount)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(
                    Color.tertiarySystemGroupedBackground,
                    in: .rect(cornerRadius: 16)
                )

                // Linked accounts
                if authenticationService.hasGoogleAccount || authenticationService.hasAppleAccount {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.Profile.linkedAccounts)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            if authenticationService.hasGoogleAccount {
                                Label(Loc.Profile.googleAccount, systemImage: "globe")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            if authenticationService.hasAppleAccount {
                                Label(Loc.Profile.appleId, systemImage: "applelogo")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.1))
                                    .foregroundStyle(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(
                        Color.tertiarySystemGroupedBackground,
                        in: .rect(cornerRadius: 16)
                    )
                }
            }
        }
    }

    // MARK: - Nickname Section

    private var nicknameSection: some View {
        CustomSectionView(
            header: Loc.Profile.nickname,
            footer: Loc.Profile.nicknameDescription
        ) {
            if isEditingNickname {
                // Inline editing
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField(Loc.Profile.enterNickname, text: $editedNickname)
                            .font(.body)
                            .fontWeight(.medium)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        HeaderButton(Loc.Actions.cancel, color: .secondary) {
                            cancelNicknameEdit()
                        }
                    }
                    if let errorMessage = nicknameErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(
                    Color.tertiarySystemGroupedBackground,
                    in: .rect(cornerRadius: 16)
                )
                .padding(.bottom, 12)
            } else {
                // Display mode
                HStack(spacing: 8) {
                    if authenticationService.nickname != nil {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(.accent)
                    } else {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authenticationService.nickname ?? Loc.Profile.nicknameNotSet)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(Loc.Profile.nicknameCurrent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                .padding(.bottom, 12)
            }
        } trailingContent: {
            if isEditingNickname {
                AsyncHeaderButton(
                    Loc.Actions.save,
                    size: .small,
                    style: .borderedProminent
                ) {
                    await saveNickname()
                }
                .disabled(editedNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                HeaderButton(
                    authenticationService.nickname != nil
                    ? Loc.Actions.edit
                    : Loc.Actions.add,
                    size: .small
                ) {
                    startNicknameEdit()
                }
            }
        }
        .animation(.default, value: isEditingNickname)
    }

    // MARK: - Learning Preferences Section

    private var learningPreferencesSection: some View {
        CustomSectionView(
            header: Loc.Settings.learningPreferences,
            footer: Loc.Settings.learningPreferencesDescription
        ) {
            Button {
                showingLearningPreferences = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.ellipsis.fill")
                        .foregroundColor(.accent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Loc.Settings.customizeLearning)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text(Loc.Settings.updateGoalsLanguages)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Account Linking Section

    private var accountLinkingSection: some View {
        CustomSectionView(
            header: Loc.Profile.accountLinking,
            footer: Loc.Profile.accountLinkingDescription
        ) {
            VStack(spacing: 12) {
                // Link Google Account (for Android compatibility)
                if !authenticationService.hasGoogleAccount {
                    Button {
                        AnalyticsService.shared.logEvent(.accountLinkingOpened)
                        Task {
                            await linkGoogleAccount()
                        }
                    } label: {
                        HStack {
                            Image(.googleLogo)
                                .resizable()
                                .frame(width: 20, height: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Loc.Profile.linkGoogleForAndroid)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(Loc.Profile.crossPlatformButtonDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                    }
                    .disabled(authenticationService.authenticationState == .loading)
                }

                // Link Apple Account (for cross-platform)
                if !authenticationService.hasAppleAccount {
                    Button {
                        AnalyticsService.shared.logEvent(.accountLinkingOpened)
                        Task {
                            await linkAppleAccount()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.title2)
                                .foregroundStyle(.black)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(Loc.Profile.linkAppleForCrossPlatform)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(Loc.Profile.crossPlatformButtonDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                    }
                    .disabled(authenticationService.authenticationState == .loading)
                }

                // All accounts linked
                if authenticationService.hasGoogleAccount && authenticationService.hasAppleAccount {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(Loc.Auth.accountsLinkedSuccessfully)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 16))
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        CustomSectionView(
            header: Loc.Auth.signOut,
            footer: Loc.Auth.yourWordsAreSafe
        ) {
            ActionButton(
                Loc.Auth.signOut,
                systemImage: "rectangle.portrait.and.arrow.right",
                color: .red
            ) {
                authenticationService.toggleSignOutView()
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Account Linking Methods

    private func linkGoogleAccount() async {
        do {
            try await authenticationService.linkGoogleAccount()
            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            HapticManager.shared.triggerNotification(type: .error)
            errorReceived(error)
        }
    }

    private func linkAppleAccount() async {
        do {
            try await authenticationService.linkAppleAccount()
            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            HapticManager.shared.triggerNotification(type: .error)
            errorReceived(error)
        }
    }

    // MARK: - Name Editing Methods

    private func startNameEdit() {
        editedName = authenticationService.displayName ?? ""
        isEditingName = true
        nameErrorMessage = nil
    }

    private func cancelNameEdit() {
        isEditingName = false
        editedName = ""
        nameErrorMessage = nil
    }

    private func saveName() async {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            nameErrorMessage = Loc.Errors.inputCannotBeEmpty
            return
        }

        nameErrorMessage = nil

        do {
            try await authenticationService.updateDisplayName(trimmedName)
            isEditingName = false
            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            nameErrorMessage = Loc.Errors.unknownError + "\n" + error.localizedDescription
            HapticManager.shared.triggerNotification(type: .error)
        }
    }

    // MARK: - Nickname Editing Methods

    private func startNicknameEdit() {
        editedNickname = authenticationService.nickname ?? ""
        isEditingNickname = true
        nicknameErrorMessage = nil
    }

    private func cancelNicknameEdit() {
        isEditingNickname = false
        editedNickname = ""
        nicknameErrorMessage = nil
    }

    private func saveNickname() async {
        let trimmedNickname = editedNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else {
            nicknameErrorMessage = Loc.Profile.nicknameCannotBeEmpty
            return
        }

        nicknameErrorMessage = nil

        do {
            try await authenticationService.updateNickname(trimmedNickname)
            isEditingNickname = false
            HapticManager.shared.triggerNotification(type: .success)
        } catch let authError as AuthenticationError {
            nicknameErrorMessage = authError.localizedDescription
            HapticManager.shared.triggerNotification(type: .error)
        } catch {
            nicknameErrorMessage = Loc.Errors.unknownError + "\n" + error.localizedDescription
            HapticManager.shared.triggerNotification(type: .error)
        }
    }
}

#Preview {
    ProfileView()
}

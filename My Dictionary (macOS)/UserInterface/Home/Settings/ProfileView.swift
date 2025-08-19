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

    var body: some View {
        ScrollViewWithCustomNavBar {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader

                // Account Information
                accountInformationSection

                // Account Linking Section
                accountLinkingSection

                // Sign Out Section
                signOutSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        } navigationBar: {
            NavigationBarView(
                title: Loc.Auth.profile.localized
            )
        }
        .groupedBackground()
        .sheet(isPresented: $authenticationService.showingSignOutView) {
            SignOutView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)

            VStack(spacing: 4) {
                Text(authenticationService.displayName ?? Loc.Settings.anonymous.localized)
                    .font(.title2)
                    .fontWeight(.semibold)

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
            header: Loc.Auth.currentAccount.localized
        ) {
            VStack(spacing: 12) {
                // Current sign-in method
                HStack {
                    Image(systemName: authenticationService.hasAppleAccount ? "applelogo" : "globe")
                        .foregroundStyle(.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authenticationService.hasAppleAccount ? "Apple ID" : "Google Account")
                            .font(.body)
                            .fontWeight(.medium)
                        Text(Loc.Auth.currentAccount.localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding(vertical: 12, horizontal: 16)
                .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)

                // Linked accounts
                if authenticationService.hasGoogleAccount || authenticationService.hasAppleAccount {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Loc.Auth.linkedAccounts.localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            if authenticationService.hasGoogleAccount {
                                Label("Google", systemImage: "globe")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accent.opacity(0.1))
                                    .foregroundStyle(.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            if authenticationService.hasAppleAccount {
                                Label("Apple ID", systemImage: "applelogo")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.label.opacity(0.1))
                                    .foregroundStyle(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                }
            }
        }
    }

    // MARK: - Account Linking Section

    private var accountLinkingSection: some View {
        CustomSectionView(
            header: Loc.Auth.accountLinking.localized,
            footer: Loc.Auth.accountLinkingDescription.localized
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
                                Text(Loc.Auth.linkGoogleForAndroid.localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text("Required for Android subscription access")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                    }
                    .disabled(authenticationService.authenticationState == .loading)
                    .buttonStyle(.plain)
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
                                Text(Loc.Auth.linkAppleForCrossPlatform.localized)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text("For cross-platform subscription sharing")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(vertical: 12, horizontal: 16)
                        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                    }
                    .disabled(authenticationService.authenticationState == .loading)
                    .buttonStyle(.plain)
                }

                // All accounts linked
                if authenticationService.hasGoogleAccount && authenticationService.hasAppleAccount {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(Loc.Auth.accountsLinkedSuccessfully.localized)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(vertical: 12, horizontal: 16)
                    .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 16)
                }
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        CustomSectionView(
            header: Loc.Auth.signOut.localized,
            footer: Loc.Auth.yourWordsAreSafe.localized
        ) {
            ActionButton(
                Loc.Auth.signOut.localized,
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
        } catch {
            errorReceived(error)
        }
    }

    private func linkAppleAccount() async {
        do {
            try await authenticationService.linkAppleAccount()
        } catch {
            errorReceived(error)
        }
    }
}

#Preview {
    ProfileView()
}

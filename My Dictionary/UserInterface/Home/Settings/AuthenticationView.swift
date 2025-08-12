//
//  AuthenticationView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

struct AuthenticationView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAccountLinking = false
    let shownBeforePaywall: Bool

    init(shownBeforePaywall: Bool = false) {
        self.shownBeforePaywall = shownBeforePaywall
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)

                Text(shownBeforePaywall ? "Sign in before subscribing" : "Sign in to sync your word lists")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text("Sign in to access your word lists across all your devices and collaborate with others.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Sign in buttons
            VStack(spacing: 16) {
                // Google Sign-In Button
                Button {
                    AnalyticsService.shared.logEvent(.signInWithGoogleTapped)
                    Task {
                        await signInWithGoogle()
                    }
                } label: {
                    Label {
                        Text("Sign in with Google")
                    } icon: {
                        Image(.googleLogo).renderingMode(.template)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .frame(height: 50)
                .disabled(authService.authenticationState == .loading)

                // Sign In with Apple Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        AnalyticsService.shared.logEvent(.signInWithAppleTapped)
                        Task {
                            await handleAppleSignIn(result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .disabled(authService.authenticationState == .loading)

                // Account Linking (if already signed in)
                if authService.isSignedIn {
                    accountLinkingSection
                }

                if shownBeforePaywall {
                    Button("Skip for now") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            if shownBeforePaywall {
                // Footer
                VStack(spacing: 8) {
                    Text("You can always sign in later from Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if authService.authenticationState == .loading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .groupedBackground()
        .navigation(
            title: "Sign In",
            mode: .inline,
            trailingContent: {
                HeaderButton("Cancel") {
                    dismiss()
                }
            }
        )
        .onChange(of: authService.authenticationState) { state in
            if state == .signedIn && !shownBeforePaywall {
                dismiss()
            }
        }
    }

    // MARK: - Account Linking Section

    private var accountLinkingSection: some View {
        VStack(spacing: 12) {
            Text("Link additional accounts")
                .font(.headline)
                .padding(.top)

            HStack(spacing: 12) {
                // Link Google Account
                if !authService.hasGoogleAccount {
                    Button {
                        AnalyticsService.shared.logEvent(.accountLinkingOpened)
                        Task {
                            await linkGoogleAccount()
                        }
                    } label: {
                        Label {
                            Text("Link Google")
                                .font(.caption)
                                .fontWeight(.medium)
                        } icon: {
                            Image(.googleLogo)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(authService.authenticationState == .loading)
                }

                // Link Apple Account
                if !authService.hasAppleAccount {
                    Button {
                        AnalyticsService.shared.logEvent(.accountLinkingOpened)
                        Task {
                            await linkAppleAccount()
                        }
                    } label: {
                        Label {
                            Text("Link Apple")
                                .font(.caption)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "applelogo")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(authService.authenticationState == .loading)
                }
            }

            if authService.hasGoogleAccount || authService.hasAppleAccount {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Accounts linked successfully")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Sign In Methods

    private func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
        } catch {
            // Handle error - you might want to show an alert
            print("Sign in error: \(error)")
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if authorization.credential is ASAuthorizationAppleIDCredential {
                do {
                    try await authService.signInWithApple()
                } catch {
                    print("Apple sign in error: \(error)")
                }
            }
        case .failure(let error):
            print("Apple sign in failed: \(error)")
        }
    }

    private func linkGoogleAccount() async {
        do {
            try await authService.linkGoogleAccount()
        } catch {
            print("Link Google account error: \(error)")
        }
    }

    private func linkAppleAccount() async {
        do {
            try await authService.linkAppleAccount()
        } catch {
            print("Link Apple account error: \(error)")
        }
    }
}

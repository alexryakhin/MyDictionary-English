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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showingAccountLinking = false
    let shownBeforePaywall: Bool

    init(shownBeforePaywall: Bool = false) {
        self.shownBeforePaywall = shownBeforePaywall
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationBarView(title: Loc.Actions.signIn.localized)

            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)

                Text(shownBeforePaywall ? Loc.Auth.signInBeforeSubscribing.localized : Loc.Auth.signInToSyncWordLists.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(Loc.Auth.signInToAccessWordLists.localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            

            // Sign in buttons
            VStack(spacing: 16) {
                // Sign In with Apple Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        authService.updateCurrentNonce()
                        if let currentNonce = authService.currentNonce {
                            request.nonce = authService.sha256(currentNonce)
                        }
                    },
                    onCompletion: { result in
                        AnalyticsService.shared.logEvent(.signInWithAppleTapped)
                        Task {
                            await handleAppleSignIn(result)
                        }
                    }
                )
                .if(colorScheme == .dark) { button in
                    button.signInWithAppleButtonStyle(.white)
                }
                .if(colorScheme == .light) { button in
                    button.signInWithAppleButtonStyle(.black)
                }
                .frame(height: 56)
                .disabled(authService.authenticationState == .loading)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Google Sign-In Button
                Button {
                    AnalyticsService.shared.logEvent(.signInWithGoogleTapped)
                    Task {
                        await signInWithGoogle()
                    }
                } label: {
                    Label {
                        Text(Loc.Auth.signInWithGoogle.localized)
                    } icon: {
                        Image(.googleLogo).renderingMode(.template)
                    }
                    .font(.system(.title2, design: .default, weight: .medium))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .frame(height: 56)
                .disabled(authService.authenticationState == .loading)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Account Linking (if already signed in)
                if authService.isSignedIn {
                    accountLinkingSection
                }

                if shownBeforePaywall {
                    Button(Loc.Actions.skipForNow.localized) {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: 300)
            .padding(.horizontal, 32)

            Spacer()

            if shownBeforePaywall {
                // Footer
                VStack(spacing: 8) {
                    Text(Loc.Auth.canAlwaysSignInLater.localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if authService.authenticationState == .loading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .padding(12)
        .groupedBackground()
        .onChange(of: authService.authenticationState) { state in
            if state == .signedIn && !shownBeforePaywall {
                dismiss()
            }
        }
    }

    // MARK: - Account Linking Section

    private var accountLinkingSection: some View {
        VStack(spacing: 12) {
                            Text(Loc.Auth.linkAdditionalAccounts.localized)
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
                            Text(Loc.Auth.linkGoogle.localized)
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
                                .stroke(Color.systemGray4, lineWidth: 1)
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
                            Text(Loc.Auth.linkApple.localized)
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
                        .foregroundStyle(.accent)
                    Text(Loc.Auth.accountsLinkedSuccessfully.localized)
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
            errorReceived(error)
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let appleIDToken = appleIDCredential.identityToken,
               let idTokenString = String(data: appleIDToken, encoding: .utf8),
               let nonce = authService.currentNonce {
                
                do {
                    // Create credential with nonce for security
                    let credential = OAuthProvider.credential(
                        providerID: .apple,
                        idToken: idTokenString,
                        rawNonce: nonce
                    )

                    let authResult = try await Auth.auth().signIn(with: credential)

                    await MainActor.run {
                        authService.currentUser = authResult.user
                        authService.authenticationState = .signedIn
                    }
                } catch {
                    errorReceived(error)
                }
            } else {
                errorReceived(AuthenticationError.appleSignInInvalidCredential)
            }
        case .failure(let error):
            errorReceived(error)
        }
    }

    private func linkGoogleAccount() async {
        do {
            try await authService.linkGoogleAccount()
        } catch {
            errorReceived(error)
        }
    }

    private func linkAppleAccount() async {
        do {
            try await authService.linkAppleAccount()
        } catch {
            errorReceived(error)
        }
    }
}

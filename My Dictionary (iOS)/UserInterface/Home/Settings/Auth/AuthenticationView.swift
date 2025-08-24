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
            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.accent)

                Text(
                    shownBeforePaywall
                    ? Loc.Auth.signInBeforeSubscribing.localized
                    : Loc.Auth.signInToSyncWordLists.localized
                )
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
                .shadow(radius: 2)



                if shownBeforePaywall {
                    Button(Loc.Actions.skipForNow.localized) {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            if shownBeforePaywall {
                // Footer
                VStack(spacing: 8) {
                    Text(Loc.Auth.canAlwaysSignInLater.localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if authService.authenticationState == .loading {
                        LoaderView()
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .if(isPad) { view in
            view
                .frame(maxWidth: 550, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .groupedBackground()
        .navigation(
            title: "Sign In",
            mode: .inline,
            trailingContent: {
                HeaderButton(Loc.Actions.cancel.localized) {
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
                    
                    // Handle Apple Sign-In name (only provided on first sign-in)
                    if let fullName = appleIDCredential.fullName {
                        let displayName = [fullName.givenName, fullName.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        if !displayName.isEmpty {
                            // Update the user's display name in Firebase
                            let changeRequest = authResult.user.createProfileChangeRequest()
                            changeRequest.displayName = displayName
                            try await changeRequest.commitChanges()
                            
                            // Save name locally as backup
                            UDService.userDisplayName = displayName
                            
                            // Update the current user reference
                            await MainActor.run {
                                authService.currentUser = authResult.user
                                authService.authenticationState = .signedIn
                            }
                        } else {
                            await MainActor.run {
                                authService.currentUser = authResult.user
                                authService.authenticationState = .signedIn
                            }
                        }
                    } else {
                        await MainActor.run {
                            authService.currentUser = authResult.user
                            authService.authenticationState = .signedIn
                        }
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


}

//
//  AuthenticationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import Combine
import SwiftUI

enum AuthenticationState {
    case signedOut
    case signedIn
    case loading
}

enum AuthenticationError: LocalizedError {
    case signInFailed
    case signOutFailed
    case userNotFound
    case networkError
    case accountLinkingFailed
    case subscriptionRequired

    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return "Failed to sign in. Please try again."
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        case .userNotFound:
            return "User not found."
        case .networkError:
            return "Network error. Please check your connection."
        case .accountLinkingFailed:
            return "Failed to link accounts. Please try again."
        case .subscriptionRequired:
            return "Pro subscription required for Google sync"
        }
    }
}

final class AuthenticationService: ObservableObject {

    static let shared = AuthenticationService()

    @Published var authenticationState: AuthenticationState = .signedOut
    @Published var currentUser: User?
    @Published var isUploadingWords: Bool = false
    @Published private(set) var showingSignOutView: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
    }

    // MARK: - Authentication State Management

    private func setupAuthStateListener() {
        print("🔍 [AuthenticationService] Setting up auth state listener")
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("📡 [AuthenticationService] Auth state changed - user: \(user?.uid ?? "nil")")
            
            DispatchQueue.main.async { [weak self] in
                if let user = user {
                    print("✅ [AuthenticationService] User signed in: \(user.uid)")
                    self?.currentUser = user
                    self?.authenticationState = .signedIn
                    
                    // First mark existing words as unsynced, then sync to Firestore, then start real-time listener
                    print("🔄 [AuthenticationService] Setting up sync for user: \(user.uid)")
                    Task {
                        do {
                            // Mark existing words as unsynced so they get uploaded
                            await DataSyncService.shared.markExistingWordsAsUnsynced(userId: user.uid)
                            
                            // Sync local words to Firestore
                            try await DataSyncService.shared.syncPrivateDictionaryToFirestore(userId: user.uid)
                            print("✅ [AuthenticationService] Local words synced to Firestore successfully")
                            
                            // Now start real-time listener after sync is complete
                            print("🔊 [AuthenticationService] Starting real-time listener for user: \(user.uid)")
                            DataSyncService.shared.startPrivateDictionaryListener(userId: user.uid)
                        } catch {
                            print("❌ [AuthenticationService] Failed to sync local words to Firestore: \(error.localizedDescription)")
                            // Still start the listener even if sync fails
                            print("🔊 [AuthenticationService] Starting real-time listener despite sync failure")
                            DataSyncService.shared.startPrivateDictionaryListener(userId: user.uid)
                        }
                    }
                } else {
                    print("❌ [AuthenticationService] User signed out")
                    self?.currentUser = nil
                    self?.authenticationState = .signedOut
                    
                    // Stop real-time listener when user signs out
                    print("🔊 [AuthenticationService] Stopping real-time listener")
                    DataSyncService.shared.stopPrivateDictionaryListener()
                }
            }
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .loading
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthenticationError.signInFailed
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthenticationError.signInFailed
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.signInFailed
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)

            DispatchQueue.main.async { [weak self] in
                self?.currentUser = authResult.user
                self?.authenticationState = .signedIn
            }

        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .signedOut
            }
            throw AuthenticationError.signInFailed
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .loading
        }

        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let result = try await withCheckedThrowingContinuation { continuation in
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate { result in
                    continuation.resume(with: result)
                }

                // Store delegate to prevent deallocation
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
            }

            guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthenticationError.signInFailed
            }

            // Create credential without nonce for simplicity
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                accessToken: nil
            )

            let authResult = try await Auth.auth().signIn(with: credential)

            DispatchQueue.main.async { [weak self] in
                self?.currentUser = authResult.user
                self?.authenticationState = .signedIn
            }

        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .signedOut
            }
            throw AuthenticationError.signInFailed
        }
    }

    // MARK: - Account Linking

    func linkGoogleAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        // Check if user has Pro subscription for Google sync
        guard SubscriptionService.shared.isProUser else {
            throw AuthenticationError.subscriptionRequired
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthenticationError.signInFailed
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthenticationError.signInFailed
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.signInFailed
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            try await currentUser.link(with: credential)
            AnalyticsService.shared.logEvent(.googleAccountLinked)

        } catch {
            AnalyticsService.shared.logEvent(.accountLinkingFailed)
            throw AuthenticationError.accountLinkingFailed
        }
    }

    func linkAppleAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }

        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let result = try await withCheckedThrowingContinuation { continuation in
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate { result in
                    continuation.resume(with: result)
                }

                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
            }

            guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthenticationError.signInFailed
            }

            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                accessToken: nil
            )

            try await currentUser.link(with: credential)
            AnalyticsService.shared.logEvent(.appleAccountLinked)

        } catch {
            AnalyticsService.shared.logEvent(.accountLinkingFailed)
            throw AuthenticationError.accountLinkingFailed
        }
    }

    // MARK: - Sign Out

    // Sign out from Firebase and Google
    func signOut() {
        Task { @MainActor in
            authenticationState = .loading

            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()

                currentUser = nil
                authenticationState = .signedOut
                toggleSignOutView()

                // Log analytics event
                AnalyticsService.shared.logEvent(.signOutTapped)
            } catch {
                authenticationState = .signedIn
                AlertCenter.shared.showAlert(with: .error(
                    title: "Oh no!",
                    message: "Something went wrong while signing out. Please try again later.")
                )
            }
        }
    }

    func toggleSignOutView() {
        withAnimation {
            showingSignOutView.toggle()
        }
    }

    // MARK: - User Management

    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    var userId: String? {
        // Use the currentUser property which is properly synchronized with authentication state
        let uid = currentUser?.uid
        print("🔍 [AuthenticationService] userId called, returning: \(uid ?? "nil")")
        print("🔍 [AuthenticationService] Current auth state: \(authenticationState)")
        print("🔍 [AuthenticationService] Current user: \(currentUser?.uid ?? "nil")")
        return uid
    }

    var userEmail: String? {
        return Auth.auth().currentUser?.email
    }

    var displayName: String? {
        return Auth.auth().currentUser?.displayName
    }

    var linkedProviders: [String] {
        return Auth.auth().currentUser?.providerData.map { $0.providerID } ?? []
    }

    var hasGoogleAccount: Bool {
        return linkedProviders.contains("google.com")
    }

    var hasAppleAccount: Bool {
        return linkedProviders.contains("apple.com")
    }
}

// MARK: - Apple Sign-In Delegate

final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

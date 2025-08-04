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
        }
    }
}

final class AuthenticationService: ObservableObject {

    static let shared = AuthenticationService()

    @Published var authenticationState: AuthenticationState = .signedOut
    @Published var currentUser: User?
    @Published var isUploadingWords: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
    }

    // MARK: - Authentication State Management

    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.currentUser = user
                    self?.authenticationState = .signedIn
                } else {
                    self?.currentUser = nil
                    self?.authenticationState = .signedOut
                }
            }
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        DispatchQueue.main.async {
            self.authenticationState = .loading
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

            DispatchQueue.main.async {
                self.currentUser = authResult.user
                self.authenticationState = .signedIn
            }

        } catch {
            DispatchQueue.main.async {
                self.authenticationState = .signedOut
            }
            throw AuthenticationError.signInFailed
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws {
        DispatchQueue.main.async {
            self.authenticationState = .loading
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

            DispatchQueue.main.async {
                self.currentUser = authResult.user
                self.authenticationState = .signedIn
            }

        } catch {
            DispatchQueue.main.async {
                self.authenticationState = .signedOut
            }
            throw AuthenticationError.signInFailed
        }
    }

    // MARK: - Account Linking

    func linkGoogleAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
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
    func signOut() async throws {
        DispatchQueue.main.async { [weak self] in
            self?.authenticationState = .loading
        }

        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()

            DispatchQueue.main.async { [weak self] in
                self?.currentUser = nil
                self?.authenticationState = .signedOut
            }
            // Log analytics event
            AnalyticsService.shared.logEvent(.signOutTapped)
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.authenticationState = .signedIn
            }
            throw AuthenticationError.signOutFailed
        }
    }

    // MARK: - User Management

    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }

    var userId: String? {
        return Auth.auth().currentUser?.uid
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

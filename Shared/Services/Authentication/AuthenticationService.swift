//
//  AuthenticationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import Combine
import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum AuthenticationState {
    case signedOut
    case signedIn
    case loading
}

enum AuthenticationError: Error, LocalizedError {
    case signInFailed
    case signOutFailed
    case userNotFound
    case networkError
    case accountLinkingFailed

    var errorDescription: String? {
        switch self {
        case .signInFailed:
            return Loc.Auth.signInFailed.localized
        case .signOutFailed:
            return Loc.Auth.signOutFailed.localized
        case .userNotFound:
            return Loc.Auth.userNotFound.localized
        case .networkError:
            return Loc.Auth.networkError.localized
        case .accountLinkingFailed:
            return Loc.Auth.accountLinkingFailed.localized
        }
    }
}

final class AuthenticationService: ObservableObject {

    static let shared = AuthenticationService()

    @Published var authenticationState: AuthenticationState = .signedOut
    @Published var currentUser: User?
    @Published var isUploadingWords: Bool = false
    @Published var showingSignOutView: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAuthStateListener()
    }

    // MARK: - Authentication State Management

    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.handleUser(user)
        }
    }

    private func handleUser(_ user: User?) {
        Task { @MainActor in
            if let user = user {
                currentUser = user
                authenticationState = .signedIn

                // Send authentication completed notification
                NotificationCenter.default.post(name: .authenticationCompleted, object: nil)

                // First mark existing words as unsynced, then sync to Firestore, then start real-time listener
                // Request push notification permissions
                await requestPushNotificationPermissions()

                // Create/update user document in Firestore with all required fields
                await createUserDocument(user: user)

                // Set up RevenueCat App User ID for cross-platform subscription sharing
                await SubscriptionService.shared.setupAppUserID()
            } else {
                currentUser = nil
                authenticationState = .signedOut

                // Immediately reset subscription status when user signs out
                SubscriptionService.shared.resetSubscriptionStatusOnSignOut()
            }
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        await MainActor.run {
            authenticationState = .loading
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthenticationError.signInFailed
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        #if os(iOS)
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
            throw AuthenticationError.signInFailed
        }
        #elseif os(macOS)
        guard let window = await NSApp.keyWindow else {
            throw AuthenticationError.signInFailed
        }
        #endif

        do {
            #if os(iOS)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            #elseif os(macOS)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            #endif

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthenticationError.signInFailed
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)

            await MainActor.run {
                currentUser = authResult.user
                authenticationState = .signedIn
            }

        } catch {
            await MainActor.run {
                authenticationState = .signedOut
            }
            throw AuthenticationError.signInFailed
        }
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws {
        await MainActor.run {
            authenticationState = .loading
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

            await MainActor.run {
                currentUser = authResult.user
                authenticationState = .signedIn
            }

        } catch {
            await MainActor.run {
                authenticationState = .signedOut
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

        #if os(iOS)
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
            throw AuthenticationError.signInFailed
        }
        #elseif os(macOS)
        guard let window = await NSApp.keyWindow else {
            throw AuthenticationError.signInFailed
        }
        let rootViewController = window.contentViewController
        #endif

        do {
            #if os(iOS)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            #elseif os(macOS)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
            #endif

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
                // Log out from RevenueCat first to prevent subscription sharing
                await SubscriptionService.shared.logoutFromRevenueCat()

                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()

                DictionaryService.shared.stopListening()
                currentUser = nil
                authenticationState = .signedOut
                toggleSignOutView()

                #if os(macOS)
                SideBarManager.shared.selectedTab = .words
                #endif

                // Log analytics event
                AnalyticsService.shared.logEvent(.signOutTapped)
            } catch {
                authenticationState = .signedIn
                AlertCenter.shared.showAlert(with: .info(
                                title: Loc.Auth.signOutErrorTitle.localized,
            message: Loc.Auth.signOutErrorMessage.localized)
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
        return authenticationState == .signedIn
    }

    var userId: String? {
        return currentUser?.uid
    }

    var userEmail: String? {
        return currentUser?.email
    }

    var displayName: String? {
        return currentUser?.displayName
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

    // MARK: - Push Notifications

    func requestPushNotificationPermissions() async {
        let _ = await MessagingService.shared.requestNotificationPermission()
    }

    /// Creates or updates the user document in Firestore with all required fields
    func createUserDocument(user: User) async {
        guard let userEmail = user.email else { return }

        do {
            let db = Firestore.firestore()

            // Create user document with all required fields
            try await db.collection("users").document(userEmail).setData([
                "userId": user.uid,
                "email": userEmail,
                "name": user.displayName ?? Loc.App.unknown.localized,
                "registrationDate": FieldValue.serverTimestamp(),
                "lastUpdated": FieldValue.serverTimestamp(),
                "platform": getCurrentPlatform(),
                "subscriptionStatus": SubscriptionService.shared.isProUser ? "pro" : "free",
                "subscriptionPlan": SubscriptionService.shared.currentPlan?.id ?? "none",
                "subscriptionExpiryDate": nil // Will be updated when subscription changes
            ], merge: true)
            
            // Register current device token if available
            if let fcmToken = await MessagingService.shared.getCurrentToken() {
                await DeviceTokenService.shared.registerDeviceToken(fcmToken)
            }
        } catch {
            errorReceived(error)
        }
    }

    /// Updates the FCM token in the user's Firestore document (legacy method - now handled by DeviceTokenService)
    @available(*, deprecated, message: "Use DeviceTokenService.shared.registerDeviceToken() instead")
    func updateFCMToken(_ token: String) async {
        await DeviceTokenService.shared.registerDeviceToken(token)
    }

    private func errorReceived(_ error: Error) {
        Task { @MainActor in
            AlertCenter.shared.showAlert(with: .error(message: error.localizedDescription))
        }
    }

    // MARK: - Platform Detection
    
    private func getCurrentPlatform() -> String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return Loc.App.unknown.localized
        #endif
    }
}

// MARK: - Apple Sign-In Delegate

final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void

    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
        #elseif os(macOS)
        guard let window = NSApp.keyWindow else {
            fatalError("No window found")
        }
        return window
        #else
        fatalError("Unsupported platform")
        #endif
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

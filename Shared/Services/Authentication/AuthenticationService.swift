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
            self?.handleUser(user)
        }
    }

    private func handleUser(_ user: User?) {
        Task { @MainActor in
            if let user = user {
                print("✅ [AuthenticationService] User signed in: \(user.uid)")
                currentUser = user
                authenticationState = .signedIn

                // First mark existing words as unsynced, then sync to Firestore, then start real-time listener
                print("🔄 [AuthenticationService] Setting up sync for user: \(user.uid)")
                do {
                    // Request push notification permissions
                    await requestPushNotificationPermissions()

                    // Create/update user document in Firestore with all required fields
                    await createUserDocument(user: user)

                    // Set up RevenueCat App User ID for cross-platform subscription sharing
                    await SubscriptionService.shared.setupAppUserID()

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
            } else {
                print("❌ [AuthenticationService] User signed out")
                currentUser = nil
                authenticationState = .signedOut

                // Immediately reset subscription status when user signs out
                SubscriptionService.shared.resetSubscriptionStatusOnSignOut()

                // Stop real-time listener when user signs out
                print("🔊 [AuthenticationService] Stopping real-time listener")
                DataSyncService.shared.stopPrivateDictionaryListener()
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

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
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

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
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
                // Log out from RevenueCat first to prevent subscription sharing
                await SubscriptionService.shared.logoutFromRevenueCat()

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
        print("🔔 [AuthenticationService] Requesting push notification permissions")

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])

            if granted {
                print("✅ [AuthenticationService] Push notification permissions granted")

                // Register for remote notifications
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ [AuthenticationService] Push notification permissions denied")
            }
        } catch {
            print("❌ [AuthenticationService] Failed to request push notification permissions: \(error)")
        }
    }

    /// Creates or updates the user document in Firestore with all required fields
    func createUserDocument(user: User) async {
        guard let userEmail = user.email else {
            print("❌ [AuthenticationService] No email available for user document creation")
            return
        }

        do {
            let db = Firestore.firestore()

            // Get current FCM token if available
            let fcmToken = Messaging.messaging().fcmToken

            // Create user document with all required fields
            try await db.collection("users").document(userEmail).setData([
                "userId": user.uid,
                "email": userEmail,
                "name": user.displayName ?? "Unknown",
                "registrationDate": FieldValue.serverTimestamp(),
                "lastUpdated": FieldValue.serverTimestamp(),
                "platform": "iOS",
                "fcmToken": fcmToken ?? "",
                "subscriptionStatus": SubscriptionService.shared.isProUser ? "pro" : "free",
                "subscriptionPlan": SubscriptionService.shared.currentPlan?.rawValue ?? "none",
                "subscriptionExpiryDate": nil // Will be updated when subscription changes
            ], merge: true)

            print("✅ [AuthenticationService] User document created/updated for: \(userEmail)")

        } catch {
            print("❌ [AuthenticationService] Failed to create user document: \(error)")
        }
    }

    /// Updates the FCM token in the user's Firestore document
    func updateFCMToken(_ token: String) async {
        guard let userEmail = AuthenticationService.shared.userEmail else {
            print("❌ [AuthenticationService] No user email available for FCM token update")
            return
        }

        do {
            let db = Firestore.firestore()

            try await db.collection("users").document(userEmail).updateData([
                "fcmToken": token,
                "lastUpdated": FieldValue.serverTimestamp()
            ])

            print("✅ [AuthenticationService] FCM token updated for user: \(userEmail)")

        } catch {
            print("❌ [AuthenticationService] Failed to update FCM token: \(error)")
        }
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

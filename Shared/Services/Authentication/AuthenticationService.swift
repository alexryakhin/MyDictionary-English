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
import CryptoKit
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
    case appleSignInCancelled
    case appleSignInInvalidCredential
    case appleSignInNotAuthorized
    case nicknameEmpty
    case nicknameInvalidFormat
    case nicknameAlreadyTaken

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
        case .appleSignInCancelled:
            return "Apple Sign In was cancelled"
        case .appleSignInInvalidCredential:
            return "Invalid Apple Sign In credential"
        case .appleSignInNotAuthorized:
            return "Apple Sign In not authorized"
        case .nicknameEmpty:
            return Loc.Auth.nicknameCannotBeEmpty.localized
        case .nicknameInvalidFormat:
            return Loc.Auth.nicknameInvalidFormat.localized
        case .nicknameAlreadyTaken:
            return Loc.Auth.nicknameAlreadyTaken.localized
        }
    }
}

final class AuthenticationService: ObservableObject {

    static let shared = AuthenticationService()

    @Published var authenticationState: AuthenticationState = .signedOut
    @Published var currentUser: User?
    @Published var isUploadingWords: Bool = false
    @Published var showingSignOutView: Bool = false
    
    private(set) var currentNonce: String?

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

                // Check if user has a display name, if not try to restore from local storage
                await checkAndRestoreDisplayName(user: user)

                // Load and sync nickname from Firebase if it exists
                await loadAndSyncNickname(user: user)

                // First mark existing words as unsynced, then sync to Firestore, then start real-time listener
                // Request push notification permissions
                await requestPushNotificationPermissions()

                // Create/update user document in Firestore with all required fields
                await createUserDocument(user: user)

                // Set up RevenueCat App User ID for cross-platform subscription sharing
                await SubscriptionService.shared.setupAppUserID()
                
                // Verify subscription ownership to prevent subscription sharing
                let ownershipVerified = await SubscriptionService.shared.verifySubscriptionOwnership()
                if !ownershipVerified {
                    // If ownership verification failed, sign out the user
                    print("🚨 [AuthenticationService] Subscription ownership verification failed - signing out user")
                    await signOut()
                    return
                }
                
                // If user had an anonymous subscription, sync it to their account
                await syncAnonymousSubscriptionIfNeeded()
            } else {
                currentUser = nil
                authenticationState = .signedOut

                // Immediately reset subscription status when user signs out
                await SubscriptionService.shared.resetSubscriptionStatusOnSignOut()
            }
        }
    }
    
    // MARK: - Display Name Restoration
    
    private func checkAndRestoreDisplayName(user: User) async {
        // If user doesn't have a display name in Firebase but we have one stored locally
        if (user.displayName == nil || user.displayName?.isEmpty == true),
           let localDisplayName = UDService.userDisplayName,
           !localDisplayName.isEmpty {
            
            do {
                // Update the user's display name in Firebase
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = localDisplayName
                try await changeRequest.commitChanges()
                
                print("✅ [AuthenticationService] Restored display name from local storage: \(localDisplayName)")
            } catch {
                print("❌ [AuthenticationService] Failed to restore display name: \(error)")
            }
        }
    }
    
    // MARK: - Nickname Sync
    
    private func loadAndSyncNickname(user: User) async {
        guard let userEmail = user.email else { return }

        do {
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(userEmail).getDocument()

            if let userData = userDoc.data(),
               let firebaseNickname = userData["nickname"] as? String,
               !firebaseNickname.isEmpty {

                // Save the nickname from Firebase to local UserDefaults
                UDService.userNickname = firebaseNickname
                print("✅ [AuthenticationService] Loaded nickname from Firebase: \(firebaseNickname)")
            }
        } catch {
            print("❌ [AuthenticationService] Failed to load nickname from Firebase: \(error)")
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
            let nonce = randomNonceString()
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

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
                        saveDisplayNameLocally(displayName)
                        
                        // Update the current user reference
                        await MainActor.run {
                            currentUser = authResult.user
                            authenticationState = .signedIn
                        }
                    } else {
                        await MainActor.run {
                            currentUser = authResult.user
                            authenticationState = .signedIn
                        }
                    }
            } else {
                await MainActor.run {
                    currentUser = authResult.user
                    authenticationState = .signedIn
                }
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
            let nonce = randomNonceString()
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)

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
                rawNonce: nonce
            )

            try await currentUser.link(with: credential)
            
            // Handle Apple Sign-In name when linking account (only provided on first sign-in)
            if let fullName = appleIDCredential.fullName {
                let displayName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                if !displayName.isEmpty {
                    // Update the user's display name in Firebase
                    let changeRequest = currentUser.createProfileChangeRequest()
                    changeRequest.displayName = displayName
                    try await changeRequest.commitChanges()
                    
                    // Save name locally as backup
                    saveDisplayNameLocally(displayName)
                }
            }
            
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
            await performSignOut()
        }
    }
    
    // Async sign out method for internal use
    private func performSignOut() async {
        authenticationState = .loading

        do {
            // Log out from RevenueCat first to prevent subscription sharing
            await SubscriptionService.shared.logoutFromRevenueCat()

            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()

            DictionaryService.shared.stopListening()
            currentUser = nil
            clearDisplayNameLocally()
            authenticationState = .signedOut
            toggleSignOutView()

            #if os(macOS)
            SideBarManager.shared.selectedTab = .myDictionary
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
        // First try to get from Firebase user
        if let firebaseDisplayName = currentUser?.displayName, !firebaseDisplayName.isEmpty {
            return firebaseDisplayName
        }
        
        // Fall back to locally stored name
        return UDService.userDisplayName
    }
    
    // MARK: - Display Name Management
    
    private func saveDisplayNameLocally(_ name: String) {
        UDService.userDisplayName = name
    }
    
    private func clearDisplayNameLocally() {
        UDService.userDisplayName = nil
    }
    
    /// Updates the user's display name in both Firebase and local storage
    func updateDisplayName(_ newName: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw AuthenticationError.signInFailed // You might want to create a specific error for this
        }
        
        // Update Firebase user profile
        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.displayName = trimmedName
        try await changeRequest.commitChanges()
        
        // Save locally as backup
        saveDisplayNameLocally(trimmedName)
        
        // Update current user reference
        await MainActor.run {
            self.currentUser = currentUser
        }
        
        // Update Firestore document
        await createUserDocument(user: currentUser)
    }
    
    /// Updates the user's nickname for discovery
    func updateNickname(_ newNickname: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        let trimmedNickname = newNickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedNickname.isEmpty else {
            throw AuthenticationError.nicknameEmpty
        }
        
        // Validate nickname format (alphanumeric and underscores only)
        let nicknameRegex = try NSRegularExpression(pattern: "^[a-z0-9_]+$")
        guard nicknameRegex.firstMatch(in: trimmedNickname, range: NSRange(trimmedNickname.startIndex..., in: trimmedNickname)) != nil else {
            throw AuthenticationError.nicknameInvalidFormat
        }
        
        // Check if nickname is already taken
        let isAvailable = await checkNicknameAvailability(trimmedNickname)
        guard isAvailable else {
            throw AuthenticationError.nicknameAlreadyTaken
        }
        
        // Save locally
        UDService.userNickname = trimmedNickname
        
        // Update Firestore document
        await createUserDocument(user: currentUser)
    }
    
    /// Checks if a nickname is available using Cloud Function
    func checkNicknameAvailability(_ nickname: String) async -> Bool {
        do {
            return try await CloudFunctionsService.shared.checkNicknameAvailability(nickname)
        } catch {
            print("❌ [AuthenticationService] Failed to check nickname availability: \(error)")
            return false
        }
    }
    
    /// Finds a user by nickname using Cloud Function
    func findUserByNickname(_ nickname: String) async -> UserInfo? {
        do {
            return try await CloudFunctionsService.shared.searchUserByNickname(nickname)
        } catch {
            print("❌ [AuthenticationService] Failed to find user by nickname: \(error)")
            return nil
        }
    }
    
    /// Search for a user by email using Cloud Function
    func searchUserByEmail(_ email: String) async throws -> UserInfo? {
        do {
            return try await CloudFunctionsService.shared.searchUserByEmail(email)
        } catch {
            print("❌ [AuthenticationService] Failed to search user by email: \(error)")
            throw AuthenticationError.userNotFound
        }
    }
    
    /// Search for a user by nickname using Cloud Function
    func searchUserByNickname(_ nickname: String) async throws -> UserInfo? {
        do {
            return try await CloudFunctionsService.shared.searchUserByNickname(nickname)
        } catch {
            print("❌ [AuthenticationService] Failed to search user by nickname: \(error)")
            throw AuthenticationError.userNotFound
        }
    }
    
    var nickname: String? {
        return UDService.userNickname
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
            var userData: [String: Any] = [
                "userId": user.uid,
                "email": userEmail,
                "name": user.displayName ?? Loc.App.unknown.localized,
                "registrationDate": FieldValue.serverTimestamp(),
                "lastUpdated": FieldValue.serverTimestamp(),
                "platform": getCurrentPlatform(),
                "subscriptionStatus": SubscriptionService.shared.isProUser ? "pro" : "free",
                "subscriptionPlan": SubscriptionService.shared.currentPlan?.id ?? "none",
                "subscriptionExpiryDate": "" // Will be updated when subscription changes
            ]
            
            // Only include nickname if it exists locally to avoid overwriting with null
            if let localNickname = UDService.userNickname, !localNickname.isEmpty {
                userData["nickname"] = localNickname
            }
            
            try await db.collection("users").document(userEmail).setData(userData, merge: true)
            
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
    
    // MARK: - Nonce Generation for Apple Sign In
    
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    // Updates current nonce with a random value
    func updateCurrentNonce() {
        currentNonce = randomNonceString()
    }

    // MARK: - Anonymous Subscription Sync

    private func syncAnonymousSubscriptionIfNeeded() async {
        // Sync anonymous subscription to user account if they had one
        await SubscriptionService.shared.syncAnonymousSubscriptionToAccount()
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
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completion(.failure(AuthenticationError.appleSignInCancelled))
            case .invalidResponse:
                completion(.failure(AuthenticationError.appleSignInInvalidCredential))
            case .notHandled:
                completion(.failure(AuthenticationError.appleSignInNotAuthorized))
            case .failed:
                completion(.failure(AuthenticationError.signInFailed))
            case .unknown:
                completion(.failure(AuthenticationError.signInFailed))
            @unknown default:
                completion(.failure(AuthenticationError.signInFailed))
            }
        } else {
            completion(.failure(error))
        }
    }
}

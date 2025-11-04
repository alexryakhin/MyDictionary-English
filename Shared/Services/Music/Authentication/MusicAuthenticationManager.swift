//
//  MusicAuthenticationManager.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

final class MusicAuthenticationManager {
    static let shared = MusicAuthenticationManager()
    
    private let keychainService = KeychainService.shared
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let spotifyAccessToken = "spotify_access_token"
        static let spotifyRefreshToken = "spotify_refresh_token"
        static let spotifyTokenExpiration = "spotify_token_expiration"
        static let appleMusicAuthorized = "apple_music_authorized"
    }
    
    private init() { }

    // MARK: - Spotify Token Management
    
    /// Save Spotify tokens to secure storage (Keychain)
    func saveSpotifyTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval) {
        let expirationDate = Date().addingTimeInterval(expiresIn)
        
        // Store sensitive tokens in Keychain
        keychainService.save(accessToken, forKey: Keys.spotifyAccessToken)
        keychainService.save(refreshToken, forKey: Keys.spotifyRefreshToken)
        
        // Store expiration date in UserDefaults (not sensitive, but needed for quick access)
        userDefaults.set(expirationDate.timeIntervalSince1970, forKey: Keys.spotifyTokenExpiration)
        
        print("✅ [MusicAuthManager] Spotify tokens saved to Keychain. Expires: \(expirationDate)")
    }
    
    /// Load Spotify tokens from secure storage (Keychain)
    func loadSpotifyTokens() -> (accessToken: String?, refreshToken: String?, expirationDate: Date?) {
        let accessToken = keychainService.loadString(forKey: Keys.spotifyAccessToken)
        let refreshToken = keychainService.loadString(forKey: Keys.spotifyRefreshToken)
        let expirationTimeInterval = userDefaults.double(forKey: Keys.spotifyTokenExpiration)
        let expirationDate = expirationTimeInterval > 0 ? Date(timeIntervalSince1970: expirationTimeInterval) : nil
        
        return (accessToken, refreshToken, expirationDate)
    }
    
    /// Clear Spotify tokens from storage (Keychain and UserDefaults)
    func clearSpotifyTokens() {
        keychainService.delete(forKey: Keys.spotifyAccessToken)
        keychainService.delete(forKey: Keys.spotifyRefreshToken)
        userDefaults.removeObject(forKey: Keys.spotifyTokenExpiration)
        print("🗑️ [MusicAuthManager] Spotify tokens cleared from Keychain.")
    }
    
    /// Check if Spotify token is valid (not expired)
    func isSpotifyTokenValid() -> Bool {
        let (_, _, expirationDate) = loadSpotifyTokens()
        guard let expiration = expirationDate else {
            return false
        }
        return expiration > Date()
    }
    
    // MARK: - Apple Music Status
    
    /// Save Apple Music authorization status
    func saveAppleMusicStatus(isAuthorized: Bool) {
        userDefaults.set(isAuthorized, forKey: Keys.appleMusicAuthorized)
    }
    
    /// Load Apple Music authorization status
    func loadAppleMusicStatus() -> Bool {
        return userDefaults.bool(forKey: Keys.appleMusicAuthorized)
    }
    
    /// Clear Apple Music authorization status
    func clearAppleMusicStatus() {
        userDefaults.removeObject(forKey: Keys.appleMusicAuthorized)
    }
    
    // MARK: - Service Status
    
    /// Check if a specific service is authenticated
    func isServiceAuthenticated(_ serviceType: MusicServiceType) -> Bool {
        switch serviceType {
        case .appleMusic:
            return loadAppleMusicStatus()
        case .spotify:
            return isSpotifyTokenValid()
        }
    }
    
    /// Get all authenticated services
    func getAuthenticatedServices() -> [MusicServiceType] {
        var services: [MusicServiceType] = []
        
        if loadAppleMusicStatus() {
            services.append(.appleMusic)
        }
        
        if isSpotifyTokenValid() {
            services.append(.spotify)
        }
        
        return services
    }
    
    /// Sign out from a specific service
    func signOut(serviceType: MusicServiceType) {
        switch serviceType {
        case .appleMusic:
            clearAppleMusicStatus()
        case .spotify:
            clearSpotifyTokens()
        }
    }
    
    /// Sign out from all services
    func signOutAll() {
        clearAppleMusicStatus()
        clearSpotifyTokens()
    }
}


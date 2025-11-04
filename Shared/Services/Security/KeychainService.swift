//
//  KeychainService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import Security

/// Service for secure storage and retrieval of sensitive data using iOS Keychain
final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName: String
    
    private init() {
        // Use bundle identifier as service name
        self.serviceName = Bundle.main.bundleIdentifier ?? "com.mydictionary.app"
    }
    
    // MARK: - Public Methods
    
    /// Save a string value to Keychain
    /// - Parameters:
    ///   - value: The string value to save
    ///   - key: The key identifier
    /// - Returns: True if save was successful, false otherwise
    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        return save(data, forKey: key)
    }
    
    /// Save data to Keychain
    /// - Parameters:
    ///   - data: The data to save
    ///   - key: The key identifier
    /// - Returns: True if save was successful, false otherwise
    @discardableResult
    func save(_ data: Data, forKey key: String) -> Bool {
        // Delete existing item if it exists
        delete(forKey: key)
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Add item to Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            print("⚠️ [KeychainService] Failed to save item for key '\(key)': \(status)")
            return false
        }
        
        return true
    }
    
    /// Load a string value from Keychain
    /// - Parameter key: The key identifier
    /// - Returns: The string value if found, nil otherwise
    func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Load data from Keychain
    /// - Parameter key: The key identifier
    /// - Returns: The data if found, nil otherwise
    func load(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            if status != errSecItemNotFound {
                print("⚠️ [KeychainService] Failed to load item for key '\(key)': \(status)")
            }
            return nil
        }
        
        return data
    }
    
    /// Delete an item from Keychain
    /// - Parameter key: The key identifier
    /// - Returns: True if deletion was successful, false otherwise
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("⚠️ [KeychainService] Failed to delete item for key '\(key)': \(status)")
            return false
        }
        
        return true
    }
    
    /// Delete all items for this service from Keychain
    /// - Returns: True if deletion was successful, false otherwise
    @discardableResult
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            print("⚠️ [KeychainService] Failed to delete all items: \(status)")
            return false
        }
        
        return true
    }
    
    /// Check if an item exists in Keychain
    /// - Parameter key: The key identifier
    /// - Returns: True if item exists, false otherwise
    func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess
    }
}


//
//  IPGeolocationService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

// MARK: - IP Geolocation Service

/// Service that determines user's physical location based on IP address
/// This is the only reliable way to detect if someone is actually in China
/// (vs. just having Chinese locale or timezone settings)
final class IPGeolocationService {
    
    // MARK: - Singleton
    
    static let shared = IPGeolocationService()
    
    // MARK: - Properties
    
    private let session = URLSession.shared
    private let geolocationURL = "https://ipapi.co/json"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Determines if the user's IP address is located in China
    /// - Returns: True if IP is in China, false otherwise
    func isIPInChina() async -> Bool {
        do {
            let location = try await getCurrentLocation()
            return location.countryCode == "CN"
        } catch {
            debugPrint("❌ [IPGeolocationService] Failed to detect location: \(error)")
            
            // If we can't determine location, assume not in China
            // This ensures features remain available even if the service fails
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentLocation() async throws -> IPLocation {
        guard let url = URL(string: geolocationURL) else {
            throw IPGeolocationError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IPGeolocationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw IPGeolocationError.httpError(httpResponse.statusCode)
        }
        
        do {
            let location = try JSONDecoder().decode(IPLocation.self, from: data)
            return location
        } catch {
            throw IPGeolocationError.parsingError(error.localizedDescription)
        }
    }
}

// MARK: - IP Location Model

struct IPLocation: Codable {
    let ip: String
    let city: String?
    let region: String?
    let country: String?
    let countryCode: String
    let timezone: String?
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case ip
        case city
        case region
        case country
        case countryCode = "country_code"
        case timezone
        case latitude
        case longitude
    }
}

// MARK: - IP Geolocation Errors

enum IPGeolocationError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case parsingError(String)
    case networkError(String)
}

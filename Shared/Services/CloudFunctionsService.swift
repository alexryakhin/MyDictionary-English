//
//  CloudFunctionsService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import FirebaseFunctions
import FirebaseAuth
import Combine

final class CloudFunctionsService: ObservableObject {
    
    static let shared = CloudFunctionsService()
    
    private let functions = Functions.functions(region: "europe-west3")
    
    // Alternative: Try without specifying region to use default
    // private let functions = Functions.functions()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var errorMessage: String?
    
    private init() {}
    
    /// Calls a Firebase Cloud Function with proper authentication handling
    /// - Parameters:
    ///   - functionName: The name of the Cloud Function to call
    ///   - data: The data to send to the function
    ///   - forceTokenRefresh: Whether to force refresh the ID token
    ///   - completion: Completion handler with the result
    func callFunction<T: Codable>(
        _ functionName: String,
        data: [String: Any],
        forceTokenRefresh: Bool = false,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        print("🔍 [CloudFunctionsService] Calling function: \(functionName)")
        print("🔍 [CloudFunctionsService] Data: \(data)")
        
        // Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ [CloudFunctionsService] User not authenticated")
            let error = CloudFunctionsError.userNotAuthenticated
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = error.localizedDescription
            }
            completion(.failure(error))
            return
        }
        
        print("✅ [CloudFunctionsService] User authenticated: \(currentUser.uid)")
        print("🔍 [CloudFunctionsService] User email: \(currentUser.email ?? "nil")")
        print("🔍 [CloudFunctionsService] User isAnonymous: \(currentUser.isAnonymous)")
        print("🔍 [CloudFunctionsService] User providerData: \(currentUser.providerData.map { $0.providerID })")
        
        // Get fresh ID token
        currentUser.getIDTokenForcingRefresh(forceTokenRefresh) { [weak self] token, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Token refresh failed: \(error.localizedDescription)")
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Authentication failed: \(error.localizedDescription)"
                }
                completion(.failure(CloudFunctionsError.tokenRefreshFailed(error)))
                return
            }
            
            guard let token = token else {
                print("❌ [CloudFunctionsService] No token available")
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "No authentication token available"
                }
                completion(.failure(CloudFunctionsError.noTokenAvailable))
                return
            }
            
            print("✅ [CloudFunctionsService] Got fresh token: \(token.prefix(50))...")
            print("🔍 [CloudFunctionsService] Token length: \(token.count)")

            // Try Firebase SDK first, then fallback to manual HTTP
            self?.tryFirebaseSDKFirst(functionName: functionName, data: data, token: token, completion: completion)
        }
    }
    
    /// Try Firebase SDK first, then fallback to manual HTTP if needed
    private func tryFirebaseSDKFirst<T: Codable>(
        functionName: String,
        data: [String: Any],
        token: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        print("🔍 [CloudFunctionsService] Trying Firebase SDK first...")
        
        let callable = functions.httpsCallable(functionName)
        
        callable.call(data) { [weak self] result, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Firebase SDK call failed: \(error.localizedDescription)")
                print("🔍 [CloudFunctionsService] Falling back to manual HTTP request...")
                
                // Fallback to manual HTTP request
                self?.callFunctionViaHTTP(functionName: functionName, data: data, token: token, completion: completion)
            } else {
                print("✅ [CloudFunctionsService] Firebase SDK call successful")
                
                // Try to decode the result
                if let data = result?.data as? [String: Any],
                   let jsonData = try? JSONSerialization.data(withJSONObject: data),
                   let decodedResult = try? JSONDecoder().decode(T.self, from: jsonData) {
                    completion(.success(decodedResult))
                } else {
                    // If T is not Codable or result is nil, return success with empty data
                    if T.self == EmptyResponse.self {
                        completion(.success(EmptyResponse() as! T))
                    } else {
                        let error = CloudFunctionsError.invalidResponse
                        DispatchQueue.main.async { [weak self] in
                            self?.errorMessage = error.localizedDescription
                        }
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Manual HTTP request to Cloud Function with explicit authentication
    private func callFunctionViaHTTP<T: Codable>(
        functionName: String,
        data: [String: Any],
        token: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let urlString = "https://europe-west3-my-dictionary-english.cloudfunctions.net/\(functionName)"
        guard let url = URL(string: urlString) else {
            completion(.failure(CloudFunctionsError.invalidInput))
            return
        }
        
        print("🔍 [CloudFunctionsService] Making HTTP request to: \(urlString)")
        print("🔍 [CloudFunctionsService] Using Bearer token: \(token.prefix(50))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Cloud Functions expect data to be wrapped in a "data" field
        let wrappedData: [String: Any] = ["data": data]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: wrappedData)
            print("🔍 [CloudFunctionsService] Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        } catch {
            print("❌ [CloudFunctionsService] Failed to serialize request data: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [CloudFunctionsService] HTTP Status: \(httpResponse.statusCode)")
                
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "nil"
                    print("🔍 [CloudFunctionsService] Response data: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    // Try to decode the response
                    if let data = data {
                        do {
                            let decodedResult = try JSONDecoder().decode(T.self, from: data)
                            print("✅ [CloudFunctionsService] Function call successful")
                            completion(.success(decodedResult))
                        } catch {
                            // If T is not Codable or result is nil, return success with empty data
                            if T.self == EmptyResponse.self {
                                print("✅ [CloudFunctionsService] Function call successful (empty response)")
                                completion(.success(EmptyResponse() as! T))
                            } else {
                                let error = CloudFunctionsError.invalidResponse
                                print("❌ [CloudFunctionsService] Failed to decode response: \(error)")
                                completion(.failure(error))
                            }
                        }
                    } else {
                        // If T is EmptyResponse, return success
                        if T.self == EmptyResponse.self {
                            print("✅ [CloudFunctionsService] Function call successful (no data)")
                            completion(.success(EmptyResponse() as! T))
                        } else {
                            let error = CloudFunctionsError.invalidResponse
                            print("❌ [CloudFunctionsService] No response data")
                            completion(.failure(error))
                        }
                    }
                } else {
                    let errorMessage = "HTTP \(httpResponse.statusCode)"
                    print("❌ [CloudFunctionsService] \(errorMessage)")
                    
                    // Try to parse error message from response
                    if let data = data,
                       let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? String {
                        print("❌ [CloudFunctionsService] Function error: \(error)")
                        completion(.failure(CloudFunctionsError.functionCallFailed(NSError(domain: "CloudFunctions", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: error]))))
                    } else {
                        completion(.failure(CloudFunctionsError.functionCallFailed(NSError(domain: "CloudFunctions", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))))
                    }
                }
            } else {
                print("❌ [CloudFunctionsService] Invalid response")
                completion(.failure(CloudFunctionsError.invalidResponse))
            }
        }.resume()
    }
    
    /// Calls a Firebase Cloud Function with proper authentication handling (async/await version)
    /// - Parameters:
    ///   - functionName: The name of the Cloud Function to call
    ///   - data: The data to send to the function
    ///   - forceTokenRefresh: Whether to force refresh the ID token
    /// - Returns: The decoded result
    func callFunction<T: Codable>(
        _ functionName: String,
        data: [String: Any],
        forceTokenRefresh: Bool = false
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            callFunction(functionName, data: data, forceTokenRefresh: forceTokenRefresh) { (result: Result<T, Error>) in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Manual HTTP request to Cloud Function (fallback method)
    func callFunctionManually(
        _ functionName: String,
        data: [String: Any],
        token: String,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let urlString = "https://europe-west3-my-dictionary-english.cloudfunctions.net/\(functionName)"
        guard let url = URL(string: urlString) else {
            completion(.failure(CloudFunctionsError.invalidInput))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Cloud Functions expect data to be wrapped in a "data" field
        let wrappedData: [String: Any] = ["data": data]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: wrappedData)
            print("🔍 [CloudFunctionsService] Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        } catch {
            print("❌ [CloudFunctionsService] Failed to serialize request data: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [CloudFunctionsService] HTTP Status: \(httpResponse.statusCode)")
                
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "nil"
                    print("🔍 [CloudFunctionsService] Response data: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    completion(.success(EmptyResponse()))
                } else {
                    let errorMessage = "HTTP \(httpResponse.statusCode)"
                    print("❌ [CloudFunctionsService] \(errorMessage)")
                    completion(.failure(CloudFunctionsError.functionCallFailed(NSError(domain: "CloudFunctions", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))))
                }
            } else {
                print("❌ [CloudFunctionsService] Invalid response")
                completion(.failure(CloudFunctionsError.invalidResponse))
            }
        }.resume()
    }
    
    // MARK: - Error Handling
    
    private func handleFunctionError(_ error: Error) -> CloudFunctionsError {
        // Check if it's a Firebase Functions error
        if let functionsError = error as? FunctionsErrorCode {
            switch functionsError {
            case .unauthenticated:
                return .userNotAuthenticated
            case .permissionDenied:
                return .permissionDenied
            case .invalidArgument:
                return .invalidInput
            case .notFound:
                return .resourceNotFound
            case .alreadyExists:
                return .resourceAlreadyExists
            case .resourceExhausted:
                return .resourceExhausted
            case .failedPrecondition:
                return .failedPrecondition
            case .aborted:
                return .aborted
            case .outOfRange:
                return .outOfRange
            case .unimplemented:
                return .unimplemented
            case .internal:
                return .internalError
            case .unavailable:
                return .serviceUnavailable
            case .dataLoss:
                return .dataLoss
            default:
                return .functionCallFailed(error)
            }
        }
        
        // Check if it's a network error
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError
            case .timedOut:
                return .timeoutError
            default:
                return .networkError
            }
        }
        
        return .functionCallFailed(error)
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    /// Checks if the current user has a valid authentication token
    func hasValidToken() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Forces a token refresh and returns the new token
    func refreshToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw CloudFunctionsError.userNotAuthenticated
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            currentUser.getIDTokenForcingRefresh(true) { token, error in
                if let error = error {
                    continuation.resume(throwing: CloudFunctionsError.tokenRefreshFailed(error))
                } else if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: CloudFunctionsError.noTokenAvailable)
                }
            }
        }
    }
    
    /// Test authentication with the Cloud Function
    func testAuthentication(completion: @escaping (Result<AuthTestResponse, Error>) -> Void) {
        print("🔍 [CloudFunctionsService] Testing authentication...")
        
        // First, let's check the current authentication state
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ [CloudFunctionsService] No authenticated user found")
            completion(.failure(CloudFunctionsError.userNotAuthenticated))
            return
        }
        
        print("🔍 [CloudFunctionsService] Current user: \(currentUser.uid)")
        print("🔍 [CloudFunctionsService] User email: \(currentUser.email ?? "nil")")
        print("🔍 [CloudFunctionsService] User isAnonymous: \(currentUser.isAnonymous)")
        print("🔍 [CloudFunctionsService] User providerData: \(currentUser.providerData.map { $0.providerID })")
        
        // Get a fresh token
        currentUser.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Token refresh failed: \(error.localizedDescription)")
                completion(.failure(CloudFunctionsError.tokenRefreshFailed(error)))
                return
            }
            
            guard let token = token else {
                print("❌ [CloudFunctionsService] No token available")
                completion(.failure(CloudFunctionsError.noTokenAvailable))
                return
            }
            
            print("✅ [CloudFunctionsService] Got fresh token: \(token.prefix(50))...")
            print("🔍 [CloudFunctionsService] Token length: \(token.count)")
            
            // Test with manual HTTP first to see the exact response
            self?.testAuthViaHTTP(token: token) { result in
                switch result {
                case .success(let response):
                    print("✅ [CloudFunctionsService] HTTP test successful: \(response)")
                    completion(.success(response))
                case .failure(let error):
                    print("❌ [CloudFunctionsService] HTTP test failed: \(error.localizedDescription)")
                    
                    // Try Firebase SDK as fallback
                    print("🔍 [CloudFunctionsService] Trying Firebase SDK as fallback...")
                    self?.callFunction("testAuth", data: [:], forceTokenRefresh: true) { (result: Result<AuthTestResponse, Error>) in
                        completion(result)
                    }
                }
            }
        }
    }
    
    /// Test authentication with the Cloud Function (async/await version)
    func testAuthentication() async throws -> AuthTestResponse {
        return try await withCheckedThrowingContinuation { continuation in
            testAuthentication { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// Test authentication via HTTP with detailed logging
    private func testAuthViaHTTP(token: String, completion: @escaping (Result<AuthTestResponse, Error>) -> Void) {
        let urlString = "https://europe-west3-my-dictionary-english.cloudfunctions.net/testAuth"
        guard let url = URL(string: urlString) else {
            completion(.failure(CloudFunctionsError.invalidInput))
            return
        }
        
        print("🔍 [CloudFunctionsService] Testing HTTP endpoint: \(urlString)")
        print("🔍 [CloudFunctionsService] Using Bearer token: \(token.prefix(50))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Cloud Functions expect data to be wrapped in a "data" field
        let wrappedData: [String: Any] = ["data": [:]]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: wrappedData)
            print("🔍 [CloudFunctionsService] Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")
        } catch {
            print("❌ [CloudFunctionsService] Failed to serialize request data: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [CloudFunctionsService] HTTP Status: \(httpResponse.statusCode)")
                print("🔍 [CloudFunctionsService] Response headers: \(httpResponse.allHeaderFields)")
                
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "nil"
                    print("🔍 [CloudFunctionsService] Response data: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            let decodedResult = try JSONDecoder().decode(AuthTestResponse.self, from: data)
                            print("✅ [CloudFunctionsService] HTTP test successful")
                            completion(.success(decodedResult))
                        } catch {
                            print("❌ [CloudFunctionsService] Failed to decode response: \(error)")
                            completion(.failure(CloudFunctionsError.invalidResponse))
                        }
                    } else {
                        print("❌ [CloudFunctionsService] No response data")
                        completion(.failure(CloudFunctionsError.invalidResponse))
                    }
                } else {
                    let errorMessage = "HTTP \(httpResponse.statusCode)"
                    print("❌ [CloudFunctionsService] \(errorMessage)")
                    
                    // Try to parse error message from response
                    if let data = data,
                       let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorResponse["error"] as? String {
                        print("❌ [CloudFunctionsService] Function error: \(error)")
                        completion(.failure(CloudFunctionsError.functionCallFailed(NSError(domain: "CloudFunctions", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: error]))))
                    } else {
                        completion(.failure(CloudFunctionsError.functionCallFailed(NSError(domain: "CloudFunctions", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))))
                    }
                }
            } else {
                print("❌ [CloudFunctionsService] Invalid response")
                completion(.failure(CloudFunctionsError.invalidResponse))
            }
        }.resume()
    }
    
    /// Test Cloud Function using default HTTPS endpoint URL
    func testFunctionViaHTTPS(
        _ functionName: String,
        data: [String: Any],
        token: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let urlString = "https://europe-west3-my-dictionary-english.cloudfunctions.net/\(functionName)"
        guard let url = URL(string: urlString) else {
            completion(.failure(CloudFunctionsError.invalidInput))
            return
        }
        
        print("🔍 [CloudFunctionsService] Testing HTTPS endpoint: \(urlString)")
        print("🔍 [CloudFunctionsService] Using Bearer token: \(token.prefix(50))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            request.httpBody = jsonData
            print("🔍 [CloudFunctionsService] Request body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        } catch {
            print("❌ [CloudFunctionsService] Failed to serialize request data: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [CloudFunctionsService] HTTP Status: \(httpResponse.statusCode)")
                print("🔍 [CloudFunctionsService] Response headers: \(httpResponse.allHeaderFields)")
                
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "nil"
                    print("🔍 [CloudFunctionsService] Response data: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    completion(.success("Function call successful"))
                } else {
                    let error = NSError(domain: "CloudFunctions", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"
                    ])
                    completion(.failure(error))
                }
            } else {
                print("❌ [CloudFunctionsService] Invalid response")
                completion(.failure(CloudFunctionsError.invalidResponse))
            }
        }.resume()
    }
    
    /// Test the testAuth function via HTTPS endpoint
    func testAuthViaHTTPS(completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(CloudFunctionsError.userNotAuthenticated))
            return
        }
        
        currentUser.getIDToken { token, error in
            if let error = error {
                completion(.failure(CloudFunctionsError.tokenRefreshFailed(error)))
                return
            }
            
            guard let token = token else {
                completion(.failure(CloudFunctionsError.noTokenAvailable))
                return
            }
            
            // Test the testAuth function
            self.testFunctionViaHTTPS("testAuth", data: [:], token: token, completion: completion)
        }
    }
    
    /// Comprehensive authentication test that can be called from the app
    func runComprehensiveAuthTest() {
        print("🧪 [CloudFunctionsService] Starting comprehensive authentication test...")
        
        // Test 1: Check if user is authenticated
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ [CloudFunctionsService] Test 1 FAILED: No authenticated user")
            return
        }
        print("✅ [CloudFunctionsService] Test 1 PASSED: User is authenticated (\(currentUser.uid))")
        
        // Test 2: Get fresh token
        currentUser.getIDTokenForcingRefresh(true) { [weak self] token, error in
            if let error = error {
                print("❌ [CloudFunctionsService] Test 2 FAILED: Token refresh failed - \(error.localizedDescription)")
                return
            }
            
            guard let token = token else {
                print("❌ [CloudFunctionsService] Test 2 FAILED: No token available")
                return
            }
            print("✅ [CloudFunctionsService] Test 2 PASSED: Got fresh token (\(token.prefix(20))...)")
            
            // Test 3: Test with Firebase SDK
            print("🔍 [CloudFunctionsService] Test 3: Testing with Firebase SDK...")
            self?.callFunction("testAuth", data: [:], forceTokenRefresh: false) { (result: Result<AuthTestResponse, Error>) in
                switch result {
                case .success(let response):
                    print("✅ [CloudFunctionsService] Test 3 PASSED: Firebase SDK call successful - \(response)")
                case .failure(let error):
                    print("❌ [CloudFunctionsService] Test 3 FAILED: Firebase SDK call failed - \(error.localizedDescription)")
                    
                    // Test 4: Fallback to manual HTTP
                    print("🔍 [CloudFunctionsService] Test 4: Testing with manual HTTP...")
                    self?.testAuthViaHTTP(token: token) { result in
                        switch result {
                        case .success(let response):
                            print("✅ [CloudFunctionsService] Test 4 PASSED: Manual HTTP call successful - \(response)")
                        case .failure(let error):
                            print("❌ [CloudFunctionsService] Test 4 FAILED: Manual HTTP call failed - \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Response Types

struct EmptyResponse: Codable {}

struct AuthTestResponse: Codable {
    let success: Bool
    let message: String
    let uid: String
    let email: String
    let timestamp: String
}

// MARK: - Errors

enum CloudFunctionsError: LocalizedError {
    case userNotAuthenticated
    case tokenRefreshFailed(Error)
    case noTokenAvailable
    case functionCallFailed(Error)
    case invalidResponse
    case permissionDenied
    case invalidInput
    case resourceNotFound
    case resourceAlreadyExists
    case resourceExhausted
    case failedPrecondition
    case aborted
    case outOfRange
    case unimplemented
    case internalError
    case serviceUnavailable
    case dataLoss
    case networkError
    case timeoutError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .tokenRefreshFailed(let error):
            return "Failed to refresh authentication token: \(error.localizedDescription)"
        case .noTokenAvailable:
            return "No authentication token available"
        case .functionCallFailed(let error):
            return "Function call failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .permissionDenied:
            return "You don't have permission to perform this action"
        case .invalidInput:
            return "Invalid input provided"
        case .resourceNotFound:
            return "Resource not found"
        case .resourceAlreadyExists:
            return "Resource already exists"
        case .resourceExhausted:
            return "Resource limit exceeded"
        case .failedPrecondition:
            return "Operation failed due to invalid state"
        case .aborted:
            return "Operation was aborted"
        case .outOfRange:
            return "Value out of valid range"
        case .unimplemented:
            return "Operation not implemented"
        case .internalError:
            return "Internal server error"
        case .serviceUnavailable:
            return "Service temporarily unavailable"
        case .dataLoss:
            return "Data loss occurred"
        case .networkError:
            return "Network connection error"
        case .timeoutError:
            return "Request timed out"
        }
    }
}

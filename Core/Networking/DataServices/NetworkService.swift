//
//  NetworkService.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

protocol APIEndpoint {
    func url(apiKey: String) -> URL?

    #if DEBUG
    var mockFileName: String { get }
    #endif
}

protocol NetworkServiceInterface {
    func request<T: Decodable, E: Error & Decodable>(
        for endpoint: APIEndpoint,
        apiKey: String,
        errorType: E.Type
    ) async throws(CoreError) -> T
}

class NetworkService: NetworkServiceInterface {

    private let featureToggleService: FeatureToggleServiceInterface
    private let errorParser: ErrorParser

    init(
        featureToggleService: FeatureToggleServiceInterface,
        errorParser: ErrorParser
    ) {
        self.featureToggleService = featureToggleService
        self.errorParser = errorParser
    }

    func request<T: Decodable, E: Error & Decodable>(
        for endpoint: APIEndpoint,
        apiKey: String,
        errorType: E.Type
    ) async throws(CoreError) -> T {

        #if DEBUG
        if featureToggleService.featureToggles.value.isEnabled(.mock_data),
           let decodedMockResponse: T = Bundle.main.decode(endpoint.mockFileName) {
            try? await Task.sleep(nanoseconds: 500_000_000)
            return decodedMockResponse
        }
        #endif

        guard let url = endpoint.url(apiKey: apiKey) else {
            throw CoreError.networkError(.invalidURL)
        }

        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            throw CoreError.networkError(.noInternetConnection)
        }

        #if DEBUG
        if let str = data.prettyPrintedJSONString {
            print("DEBUG RequestURL \(url.absoluteString), data: \(str)")
        }
        #endif

        if let error = errorParser.parseResponseError(response, data: data, type: errorType) {
            throw error
        }

        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            throw CoreError.networkError(.decodingError)
        }
    }
}

#if DEBUG
class NetworkServiceMock: NetworkServiceInterface {

    init() {}

    func request<T: Decodable, E: Error & Decodable>(
        for endpoint: APIEndpoint,
        apiKey: String,
        errorType: E.Type
    ) async throws(CoreError) -> T {
        if let decodedMockResponse: T = Bundle.main.decode(endpoint.mockFileName) {
            try? await Task.sleep(nanoseconds: 500_000_000)
            return decodedMockResponse
        } else {
            throw CoreError.networkError(.invalidResponse())
        }
    }
}
#endif

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case spoonacularError(Error)
    case invalidResponseWithStatusCode(Int)
}

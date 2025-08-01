//
//  BaseAPIService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

protocol APIServiceInterface {
    var baseURL: String { get }
    var apiKey: String { get }

    func fetchData<T: Decodable, P: APIPath>(from path: P, customParams: [CustomQueryParameter]) async throws -> T
}

open class BaseAPIService: APIServiceInterface {

    open var baseURL: String { fatalError("baseURL must be overridden") }
    open var apiKey: String { fatalError("apiKey must be overridden") }

    private let decoder: JSONDecoder

    init(decoder: JSONDecoder) {
        self.decoder = decoder
    }

    func buildURL<P: APIPath>(for path: P, customParams: [CustomQueryParameter]) throws -> URL {
        var components = URLComponents(string: baseURL + path.path)
        var queryItems = path.queryParams ?? []
        if customParams.contains(.apiKey) {
            queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw CoreError.networkError(.invalidURL)
        }
        return url
    }

    /// Generic method to fetch and decode data from any API
    func fetchData<T: Decodable, P: APIPath>(from path: P, customParams: [CustomQueryParameter]) async throws -> T {
        let url = try buildURL(for: path, customParams: customParams)
        let (data, _) = try await URLSession.shared.data(from: url)
        #if DEBUG
        if let string = data.prettyPrintedJSONString {
            print("DEBUG50\nURL: \(url)\nPath: \(path.path)\nJSON: \(string)\\")
        }
        #endif
        return try decoder.decode(T.self, from: data)
    }
}

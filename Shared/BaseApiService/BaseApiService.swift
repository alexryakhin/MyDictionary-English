//
//  BaseApiService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

class BaseApiService: ApiServiceInterface {

    var baseURL: String { fatalError("baseURL must be overridden") }
    var apiKey: String { fatalError("apiKey must be overridden") }

    func buildURL(for path: ApiPath, customParams: [CustomQueryParam]) throws -> URL {
        var components = URLComponents(string: baseURL + path.path)
        var queryItems = path.queryParams ?? []
        if customParams.contains(.apiKey) {
            queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw ApiError.invalidURL
        }
        return url
    }

    /// Generic method to fetch and decode data from any API
    func fetchData<T: Codable>(from path: ApiPath, customParams: [CustomQueryParam]) async throws -> T {
        let url = try buildURL(for: path, customParams: customParams)
        let (data, _) = try await URLSession.shared.data(from: url)
        if let string = data.prettyPrintedJSONString {
            print("DEBUG50\nURL: \(url)\nPath: \(path.path)\nJSON: \(string)\\")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

//
//  ApiServiceInterface.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

protocol ApiServiceInterface {
    var baseURL: String { get }
    var apiKey: String { get }

    func fetchData<T: Codable>(from path: ApiPath, customParams: [CustomQueryParam]) async throws -> T
}

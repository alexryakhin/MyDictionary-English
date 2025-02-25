//
//  ApiError.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

enum ApiError: Error {
    case invalidURL
    case decodingError
    case networkError(Error)
}

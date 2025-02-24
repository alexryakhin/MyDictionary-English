//
//  ApiPath.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/24/25.
//

import Foundation

protocol ApiPath {
    var path: String { get }
    var queryParams: [URLQueryItem]? { get }
}

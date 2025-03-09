//
//  ApiPath.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

public protocol APIPath {
    var path: String { get }
    var queryParams: [URLQueryItem]? { get }
}

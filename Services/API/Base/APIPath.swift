//
//  ApiPath.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation

protocol APIPath {
    var path: String { get }
    var queryParams: [URLQueryItem]? { get }
}

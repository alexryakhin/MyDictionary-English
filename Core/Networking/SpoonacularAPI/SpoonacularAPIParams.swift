//
//  SpoonacularAPIParams.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/22/24.
//

import Foundation

protocol SpoonacularAPIParams {
    func queryItems() -> [URLQueryItem]
}

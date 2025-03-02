//
//  SpoonacularServerError.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 9/23/24.
//

struct SpoonacularServerError: Decodable, Error {
    let code: Int
    let message: String
    let status: String
}

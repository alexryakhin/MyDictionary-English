//
//  Review.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

struct Review: Codable, Identifiable {
    let id: Int
    let user: String
    let rating: Int
    let comment: String
    let date: Date
}

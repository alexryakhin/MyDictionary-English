//
//  ShoppingListItem.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/16/24.
//

import Foundation

struct ShoppingListItem: Codable, Identifiable {
    let id: Int
    let name: String
    let amount: Double
    let unit: String
    let isChecked: Bool
}

//
//  Intolerance.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/23/24.
//

import Foundation

enum Intolerance: String {
    case dairy = "Dairy"
    case egg = "Egg"
    case gluten = "Gluten"
    case grain = "Grain"
    case peanut = "Peanut"
    case seafood = "Seafood"
    case sesame = "Sesame"
    case shellfish = "Shellfish"
    case soy = "Soy"
    case sulfite = "Sulfite"
    case treeNut = "Tree Nut"
    case wheat = "Wheat"
}

extension Array where Element == Intolerance {
    var toString: String {
        self.map { $0.rawValue }.joined(separator: ",")
    }
}

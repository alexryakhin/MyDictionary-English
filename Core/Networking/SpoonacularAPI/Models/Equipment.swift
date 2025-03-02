//
//  Equipment.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 6/23/24.
//

import Foundation

enum Equipment: String {
    case pan = "Pan"
    case fryingPan = "Frying Pan"
    case bowl = "Bowl"
    case blender = "Blender"
    case oven = "Oven"
    case microwave = "Microwave"
    case knife = "Knife"
    case cuttingBoard = "Cutting Board"
    case spatula = "Spatula"
    case whisk = "Whisk"
    case grater = "Grater"
    case pot = "Pot"
    case saucepan = "Saucepan"
    case bakingSheet = "Baking Sheet"
    case mixer = "Mixer"
    case foodProcessor = "Food Processor"
    case measuringCup = "Measuring Cup"
    case measuringSpoon = "Measuring Spoon"
    case rollingPin = "Rolling Pin"
    case colander = "Colander"
    case peeler = "Peeler"
    case ladle = "Ladle"
    case tongs = "Tongs"
    case kitchenScale = "Kitchen Scale"
    case thermomether = "Thermometer"
}

extension Array where Element == Equipment {
    var toString: String {
        self.map { $0.rawValue }.joined(separator: ",")
    }
}

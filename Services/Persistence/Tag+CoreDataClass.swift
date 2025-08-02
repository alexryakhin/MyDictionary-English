//
//  Tag+CoreDataClass.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData

@objc(CDTag)
final class CDTag: NSManagedObject, Identifiable {
    var wordsArray: [CDWord] {
        let set = words as? Set<CDWord> ?? []
        return Array(set).sorted { $0.timestamp ?? Date.distantPast > $1.timestamp ?? Date.distantPast }
    }

    var colorValue: TagColor {
        TagColor(rawValue: color ?? "blue") ?? .blue
    }
} 

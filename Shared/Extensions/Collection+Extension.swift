//
//  Collection+Extension.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation

public extension Collection {

    var isNotEmpty: Bool { !isEmpty }

    var nilIfEmpty: Self? {
        return isNotEmpty ? self : nil
    }

    subscript(safe index: Index) -> Element? {
        if indices.contains(index) {
            return self[index]
        } else {
            return nil
        }
    }
}

public extension Collection where Element: Equatable {

    var removedDuplicates: [Element] {
       var uniqueElements: [Element] = []
       for element in self where !uniqueElements.contains(element) {
           uniqueElements.append(element)
       }
       return uniqueElements
    }
}

public extension Sequence {
    @inlinable func `if`(_ condition: Bool, transform: (Self) -> Self) -> Self {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

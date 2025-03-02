//
//  Array+Extension.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 10/1/24.
//
import Foundation

extension Array {

    func contains<T>(_: T.Type) -> Bool {
        return contains(where: { $0 is T })
    }

    func first<T>(_: T.Type) -> T? {
        return first(where: { $0 is T }) as? T
    }

    func last<T>(_: T.Type) -> T? {
        return last(where: { $0 is T }) as? T
    }

    func firstIndex<T>(_: T.Type) -> Int? {
        return firstIndex(where: { $0 is T })
    }

    func lastIndex<T>(_: T.Type) -> Int? {
        return lastIndex(where: { $0 is T })
    }

    func castMap<T>(_: T.Type) -> [T] {
        return self.compactMap({ $0 as? T })
    }

    /// Returns array divided into arrays with desired size
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

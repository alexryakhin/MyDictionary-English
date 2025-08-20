//
//  Tag+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//
//

import Foundation
import CoreData

extension CDTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTag> {
        return NSFetchRequest<CDTag>(entityName: "Tag")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var words: NSSet?
    @NSManaged public var idioms: NSSet?
}

// MARK: Generated accessors for words
extension CDTag {

    @objc(addWordsObject:)
    @NSManaged public func addToWords(_ value: CDWord)

    @objc(removeWordsObject:)
    @NSManaged public func removeFromWords(_ value: CDWord)

    @objc(addWords:)
    @NSManaged public func addToWords(_ values: NSSet)

    @objc(removeWords:)
    @NSManaged public func removeFromWords(_ values: NSSet)

}

// MARK: Generated accessors for idioms
extension CDTag {

    @objc(addIdiomsObject:)
    @NSManaged public func addToIdioms(_ value: CDIdiom)

    @objc(removeIdiomsObject:)
    @NSManaged public func removeFromIdioms(_ value: CDIdiom)

    @objc(addIdioms:)
    @NSManaged public func addToIdioms(_ values: NSSet)

    @objc(removeIdioms:)
    @NSManaged public func removeFromIdioms(_ values: NSSet)

} 

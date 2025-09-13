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

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDTag> {
        return NSFetchRequest<CDTag>(entityName: "Tag")
    }

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var color: String?
    @NSManaged var timestamp: Date?
    @NSManaged var words: NSSet?
    @NSManaged var idioms: NSSet?
}

// MARK: Generated accessors for words
extension CDTag {

    @objc(addWordsObject:)
    @NSManaged func addToWords(_ value: CDWord)

    @objc(removeWordsObject:)
    @NSManaged func removeFromWords(_ value: CDWord)

    @objc(addWords:)
    @NSManaged func addToWords(_ values: NSSet)

    @objc(removeWords:)
    @NSManaged func removeFromWords(_ values: NSSet)

}

// MARK: Generated accessors for idioms
extension CDTag {

    @objc(addIdiomsObject:)
    @NSManaged func addToIdioms(_ value: CDIdiom)

    @objc(removeIdiomsObject:)
    @NSManaged func removeFromIdioms(_ value: CDIdiom)

    @objc(addIdioms:)
    @NSManaged func addToIdioms(_ values: NSSet)

    @objc(removeIdioms:)
    @NSManaged func removeFromIdioms(_ values: NSSet)

} 

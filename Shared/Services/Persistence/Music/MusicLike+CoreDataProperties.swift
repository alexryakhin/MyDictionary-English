//
//  MusicLike+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

extension CDMusicLike {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMusicLike> {
        return NSFetchRequest<CDMusicLike>(entityName: "MusicLike")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var songId: String?
    @NSManaged public var itemId: String?
    @NSManaged public var itemType: String?
    @NSManaged public var likedAt: Date?
}

extension CDMusicLike: Identifiable {

}


//
//  MusicLesson+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

extension CDMusicLesson {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMusicLesson> {
        return NSFetchRequest<CDMusicLesson>(entityName: "MusicLesson")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var songId: String?
    @NSManaged public var adaptedContent: Data?
    @NSManaged public var userLevel: String?
    @NSManaged public var savedAt: Date?
    @NSManaged public var lastAccessed: Date?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var hookData: Data?
    @NSManaged public var lyricsData: Data?
}

extension CDMusicLesson: Identifiable {

}


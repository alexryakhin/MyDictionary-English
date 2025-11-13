//
//  SongLessonSession+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

extension CDSongLessonSession {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSongLessonSession> {
        return NSFetchRequest<CDSongLessonSession>(entityName: "SongLessonSession")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var songId: String?
    @NSManaged public var songData: Data? // JSON encoded Song
    @NSManaged public var lessonData: Data? // JSON encoded AdaptedLesson
    @NSManaged public var sessionData: Data? // JSON encoded MusicDiscoveringSession
    @NSManaged public var isComplete: Bool
    @NSManaged public var date: Date?
    @NSManaged public var lastAccessed: Date?
    @NSManaged public var targetLanguage: String?
    @NSManaged public var cefrLevel: String?
    @NSManaged public var score: Int32
    @NSManaged public var correctAnswers: Int32
    @NSManaged public var totalQuestions: Int32
    @NSManaged public var isFavorite: Bool
    @NSManaged public var quizSessionId: UUID?
    @NSManaged public var hookData: Data?
    @NSManaged public var lyricsData: Data?
}

extension CDSongLessonSession : Identifiable {
    
}


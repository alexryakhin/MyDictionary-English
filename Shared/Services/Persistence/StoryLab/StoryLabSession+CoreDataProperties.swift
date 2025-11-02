//
//  StoryLabSession+CoreDataProperties.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation
import CoreData

extension CDStoryLabSession {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStoryLabSession> {
        return NSFetchRequest<CDStoryLabSession>(entityName: "StoryLabSession")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var storyData: Data? // JSON encoded AIStoryResponse
    @NSManaged public var answersData: Data? // JSON encoded answers dictionary
    @NSManaged public var configData: Data? // JSON encoded StoryLabConfig
    @NSManaged public var score: Int32
    @NSManaged public var correctAnswers: Int32
    @NSManaged public var totalQuestions: Int32
    @NSManaged public var discoveredWordsData: Data? // JSON encoded Set<String>
    @NSManaged public var title: String?
    @NSManaged public var targetLanguage: String?
    @NSManaged public var cefrLevel: String?
    @NSManaged public var isComplete: Bool
    @NSManaged public var currentPageIndex: Int32
}

extension CDStoryLabSession : Identifiable {
    
}


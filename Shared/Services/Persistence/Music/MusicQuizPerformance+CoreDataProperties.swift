//
//  MusicQuizPerformance+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation
import CoreData

extension CDMusicQuizPerformance {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDMusicQuizPerformance> {
        return NSFetchRequest<CDMusicQuizPerformance>(entityName: "MusicQuizPerformance")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var songId: String?
    @NSManaged public var quizItemId: String?
    @NSManaged public var isCorrect: Bool
    @NSManaged public var answeredAt: Date?
    @NSManaged public var timeSpent: Double
}

extension CDMusicQuizPerformance: Identifiable {

}


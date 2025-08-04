//
//  QuizSession+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDQuizSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDQuizSession> {
        return NSFetchRequest<CDQuizSession>(entityName: "QuizSession")
    }

    @NSManaged public var accuracy: Double
    @NSManaged public var correctAnswers: Int32
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var quizType: String?
    @NSManaged public var score: Int32
    @NSManaged public var totalWords: Int32
    @NSManaged public var wordsPracticed: Data?

}

extension CDQuizSession : Identifiable {

} 
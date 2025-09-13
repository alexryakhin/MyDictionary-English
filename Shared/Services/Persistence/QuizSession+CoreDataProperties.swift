//
//  QuizSession+CoreDataProperties.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import Foundation
import CoreData

extension CDQuizSession {

    @nonobjc class func fetchRequest() -> NSFetchRequest<CDQuizSession> {
        return NSFetchRequest<CDQuizSession>(entityName: "QuizSession")
    }

    @NSManaged var accuracy: Double
    @NSManaged var correctAnswers: Int32
    @NSManaged var date: Date?
    @NSManaged var duration: Double
    @NSManaged var id: UUID?
    @NSManaged var quizType: String?
    @NSManaged var score: Int32
    @NSManaged var totalWords: Int32
    @NSManaged var wordsPracticed: Data?

    var quiz: Quiz? {
        Quiz(rawValue: quizType.orEmpty)
    }
}

extension CDQuizSession : Identifiable {

} 

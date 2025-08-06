//
//  TagService.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import Foundation
import CoreData
import Combine

final class TagService {

    static let shared = TagService()

    private let coreDataService: CoreDataService = .shared

    private init() {}
    
    // MARK: - Tag Management
    
    func getAllTags() -> [CDTag] {
        let request = CDTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try coreDataService.context.fetch(request)
        } catch {
            print("Error fetching tags: \(error)")
            return []
        }
    }
    
    func createTag(name: String, color: TagColor) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        
        // Check if tag with same name already exists
        let request = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            let existingTags = try coreDataService.context.fetch(request)
            if !existingTags.isEmpty {
                throw CoreError.internalError(.tagAlreadyExists)
            }
        } catch {
            throw error
        }
        
        let newTag = CDTag(context: coreDataService.context)
        newTag.id = UUID()
        newTag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newTag.color = color.rawValue
        newTag.timestamp = Date()
        
        try coreDataService.saveContext()
    }
    
    func deleteTag(_ tag: CDTag) throws {
        coreDataService.context.delete(tag)
        try coreDataService.saveContext()
    }
    
    func updateTag(_ tag: CDTag, name: String, color: TagColor) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CoreError.internalError(.inputCannotBeEmpty)
        }
        
        // Check if another tag with same name already exists
        let request = CDTag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND id != %@", 
                                      name.trimmingCharacters(in: .whitespacesAndNewlines), 
                                      tag.id?.uuidString ?? "")
        
        do {
            let existingTags = try coreDataService.context.fetch(request)
            if !existingTags.isEmpty {
                throw CoreError.internalError(.tagAlreadyExists)
            }
        } catch {
            throw error
        }
        
        tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        tag.color = color.rawValue
        
        try coreDataService.saveContext()
    }
    
    // MARK: - Word-Tag Relationships
    
    func addTagToWord(_ tag: CDTag, word: CDWord) throws {
        guard !isWordTagged(word, with: tag) else {
            throw CoreError.internalError(.tagAlreadyAssigned)
        }
        
        // Check if word already has 5 tags
        if word.tagsArray.count >= 5 {
            throw CoreError.internalError(.maxTagsReached)
        }
        
        tag.addToWords(word)
        try coreDataService.saveContext()
    }
    
    func removeTagFromWord(_ tag: CDTag, word: CDWord) throws {
        guard isWordTagged(word, with: tag) else {
            throw CoreError.internalError(.tagNotAssigned)
        }
        
        tag.removeFromWords(word)
        try coreDataService.saveContext()
    }
    
    func getWordsForTag(_ tag: CDTag) -> [CDWord] {
        return tag.wordsArray
    }
    
    func getTagsForWord(_ word: CDWord) -> [CDTag] {
        return word.tagsArray
    }
    
    func isWordTagged(_ word: CDWord, with tag: CDTag) -> Bool {
        return word.tagsArray.contains { $0.id == tag.id }
    }
} 

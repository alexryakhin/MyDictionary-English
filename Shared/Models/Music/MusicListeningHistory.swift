//
//  MusicListeningHistory.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation

struct MusicListeningHistory: Identifiable, Codable {
    let id: String
    let song: Song
    let listenedAt: Date
    var listeningDuration: TimeInterval
    var playCount: Int
    var completed: Bool
    var lastPosition: TimeInterval
    
    init(song: Song, listeningDuration: TimeInterval = 0, playCount: Int = 1, completed: Bool = false, lastPosition: TimeInterval = 0) {
        self.id = UUID().uuidString
        self.song = song
        self.listenedAt = Date()
        self.listeningDuration = listeningDuration
        self.playCount = playCount
        self.completed = completed
        self.lastPosition = lastPosition
    }
    
    init(id: String, song: Song, listenedAt: Date, listeningDuration: TimeInterval, playCount: Int, completed: Bool, lastPosition: TimeInterval) {
        self.id = id
        self.song = song
        self.listenedAt = listenedAt
        self.listeningDuration = listeningDuration
        self.playCount = playCount
        self.completed = completed
        self.lastPosition = lastPosition
    }
    
    mutating func incrementPlayCount() {
        playCount += 1
    }
    
    mutating func updateListeningDuration(_ duration: TimeInterval) {
        listeningDuration += duration
    }
    
    mutating func markCompleted() {
        completed = true
    }
    
    mutating func updatePosition(_ position: TimeInterval) {
        lastPosition = position
    }
}


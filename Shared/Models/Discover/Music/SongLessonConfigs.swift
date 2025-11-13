//
//  SongLessonConfigs.swift
//  Shared
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import Foundation

struct MusicPlayerConfig: Codable, Hashable {
    let song: Song
    let lyrics: SongLyrics
    
    static func == (lhs: MusicPlayerConfig, rhs: MusicPlayerConfig) -> Bool {
        lhs.song.id == rhs.song.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(song.id)
    }
}

struct SongLessonConfig: Hashable {
    let song: Song
    let lesson: AdaptedLesson
    let session: MusicDiscoveringSession
    
    static func == (lhs: SongLessonConfig, rhs: SongLessonConfig) -> Bool {
        lhs.session.id == rhs.session.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(session.id)
    }
}

struct SongLessonResultsConfig: Hashable {
    let session: MusicDiscoveringSession
    let song: Song
    
    static func == (lhs: SongLessonResultsConfig, rhs: SongLessonResultsConfig) -> Bool {
        lhs.session.id == rhs.session.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(session.id)
    }
}

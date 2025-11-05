//
//  RecommendationItem.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

/// Union type for recommendation items (artists, albums, songs)
enum RecommendationItem: Identifiable, Hashable {
    case artist(RecommendationArtist)
    case album(RecommendationAlbum)
    case song(RecommendationSong)
    
    var id: String {
        switch self {
        case .artist(let artist):
            return artist.id
        case .album(let album):
            return album.id
        case .song(let song):
            return song.id
        }
    }
    
    var title: String {
        switch self {
        case .artist(let artist):
            return artist.name
        case .album(let album):
            return album.name
        case .song(let song):
            return song.title
        }
    }
    
    var subtitle: String {
        switch self {
        case .artist(let artist):
            return "Artist"
        case .album(let album):
            return album.artist
        case .song(let song):
            return song.artist
        }
    }
    
    // Artwork URLs are fetched dynamically from Apple Music, not stored in Firestore
    var artworkURL: String? {
        return nil // Will be fetched when displaying
    }
    
    var reason: String? {
        switch self {
        case .artist(let artist):
            return artist.reason
        case .album(let album):
            return album.reason
        case .song(let song):
            return song.reason
        }
    }
    
    var type: RecommendationItemType {
        switch self {
        case .artist:
            return .artist
        case .album:
            return .album
        case .song:
            return .song
        }
    }
}

enum RecommendationItemType: String {
    case artist = "artist"
    case album = "album"
    case song = "song"
}


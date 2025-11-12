//
//  ContentType.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import Foundation

enum ContentType: String, CaseIterable, Identifiable, Codable {
    case music = "music"
    case stories = "stories"
    // Future content types can be added here:
    // case video = "video"
    // case podcast = "podcast"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .music:
            return Loc.Discover.ContentType.music
        case .stories:
            return Loc.Discover.ContentType.stories
        }
    }
}


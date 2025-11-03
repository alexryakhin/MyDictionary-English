//
//  DiscoverViewModel.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import Foundation
import SwiftUI

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var selectedContentType: ContentType = .music
    
    init() {
        // Initialize with music as default
        selectedContentType = .music
    }
}


//
//  DiscoverViewModel.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
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










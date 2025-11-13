//
//  DiscoverMacViewModel.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import Foundation

@MainActor
final class DiscoverMacViewModel: ObservableObject {
    @Published var selectedContentType: ContentType = .music {
        didSet {
            guard selectedContentType != oldValue else { return }
            handleContentTypeChange()
        }
    }
    
    private func handleContentTypeChange() {
        let sideBarManager = SideBarManager.shared
        
        switch selectedContentType {
        case .music:
            sideBarManager.discoverDetail = .music(.overview)
        case .stories:
            sideBarManager.discoverDetail = .story(.overview)
        }
    }
    
    func resetForInitialDisplay() {
        handleContentTypeChange()
    }
}

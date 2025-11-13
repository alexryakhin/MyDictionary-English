//
//  DiscoverContentView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct DiscoverContentView: View {
    @ObservedObject var discoverViewModel: DiscoverMacViewModel

    var body: some View {
        Group {
            switch discoverViewModel.selectedContentType {
            case .music:
                MusicDiscoveringContentView()
            case .stories:
                StoryLabConfigurationView()
            }
        }
        .onAppear {
            discoverViewModel.resetForInitialDisplay()
        }
        .navigationTitle(Loc.Discover.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Picker(
                    Loc.Discover.ContentType.fiterTitle,
                    selection: $discoverViewModel.selectedContentType
                ) {
                    ForEach(ContentType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }
        }
    }
}

//
//  DiscoverLessonWindowPlaceholderView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct DiscoverLessonWindowPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.secondary)

            Text(Loc.MusicDiscovering.View.emptyTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(Loc.MusicDiscovering.View.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.systemGroupedBackground)
    }
}


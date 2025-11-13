//
//  DiscoverDetailView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct DiscoverDetailView: View {
    let detail: SideBarManager.DiscoverDetail
    
    var body: some View {
        switch detail {
        case .music(let musicDetail):
            MusicDiscoverDetailView(detail: musicDetail)
        case .story(let storyDetail):
            StoryDiscoverDetailView(detail: storyDetail)
        }
    }
}

private struct MusicDiscoverDetailView: View {
    let detail: SideBarManager.DiscoverDetail.MusicDetail
    
    var body: some View {
        switch detail {
        case .overview:
            DiscoverOverviewPlaceholderView(
                icon: "sparkles",
                title: Loc.MusicDiscovering.View.Section.recommendedForYou,
                subtitle: Loc.MusicDiscovering.View.description
            )
        case .songInfo(let song):
            SongLessonInfoDetailView(song: song)
                .id(song.id)
        case .lessonResults(let session, let song):
            SongLessonResultsDetailView(session: session, song: song)
                .id(song.id)
        }
    }
}

private struct StoryDiscoverDetailView: View {
    let detail: SideBarManager.DiscoverDetail.StoryDetail
    
    var body: some View {
        switch detail {
        case .overview:
            DiscoverOverviewPlaceholderView(
                icon: "book.closed",
                title: Loc.StoryLab.title,
                subtitle: Loc.StoryLab.Configuration.description
            )
        case .reading(let config):
            StoryLabReadingView(config: config, isPresentedModally: false)
        case .results(let summary):
            StoryLabResultsDetailView(summary: summary)
        case .error(let message):
            StoryLabErrorView(message: message)
        case .loading:
            StoryLabLoadingView()
        }
    }
}

struct DiscoverOverviewPlaceholderView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .groupedBackground()
    }
}

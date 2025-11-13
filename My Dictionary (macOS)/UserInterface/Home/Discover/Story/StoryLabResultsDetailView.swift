//
//  StoryLabResultsDetailView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct StoryLabResultsDetailView: View {
    let summary: StoryLabResultsConfig
    
    var body: some View {
        if let session = summary.session,
           let story = summary.story,
           let config = summary.config {
            StoryLabResultsView(
                session: session,
                story: story,
                config: config,
                showStreak: summary.showStreak,
                currentDayStreak: summary.currentDayStreak,
                isPresentedModally: false
            )
        } else {
            DiscoverOverviewPlaceholderView(
                icon: "book.closed",
                title: Loc.StoryLab.Results.title,
                subtitle: Loc.StoryLab.Configuration.description
            )
        }
    }
}


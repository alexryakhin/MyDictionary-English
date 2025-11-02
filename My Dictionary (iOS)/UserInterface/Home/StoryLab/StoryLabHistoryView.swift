//
//  StoryLabHistoryView.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI

struct StoryLabHistoryView: View {
    @StateObject private var repository = StoryLabSessionsRepository()
    @State private var navigationManager = NavigationManager.shared
    @State private var selectedSession: CDStoryLabSession?
    
    var body: some View {
        Group {
            if repository.sessions.isEmpty {
                emptyStateView
            } else {
                sessionsList
            }
        }
        .navigation(
            title: Loc.StoryLab.History.title,
            mode: .large,
            showsBackButton: true
        )
        .sheet(item: $selectedSession) { session in
            if let storySession = session.toStorySession(),
               let story = session.story,
               let config = session.config {
                // Show reading view if incomplete, results if complete
                if storySession.isComplete {
                    StoryLabResultsView(
                        session: storySession,
                        story: story,
                        config: config,
                        showStreak: false,
                        currentDayStreak: nil
                    )
                } else {
                    // Resume from current page
                    StoryLabReadingView(config: config)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(Loc.StoryLab.History.emptyTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(Loc.StoryLab.History.emptyDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sessions List
    
    private var sessionsList: some View {
        List {
            ForEach(repository.sessions) { session in
                Button {
                    selectedSession = session
                } label: {
                    StoryLabSessionRow(session: session)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                repository.deleteSessions(at: indexSet)
            }
        }
    }
}

//
//  StoryLabHistoryView.swift
//  My Dictionary
//
//  Created by AI Assistant
//

import SwiftUI

struct StoryLabHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var repository = StoryLabSessionsRepository()
    @State private var selectedSession: CDStoryLabSession?
    
    var body: some View {
        Group {
            if repository.sessions.isEmpty {
                emptyStateView
            } else {
                sessionsList
            }
        }
        .safeAreaBarIfAvailable(edge: .top) {
            HStack {
                Text(Loc.StoryLab.History.title)
                Spacer()
                HeaderButton(Loc.Actions.done) {
                    dismiss()
                }
            }
            .padding(vertical: 12, horizontal: 16)
        }
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
                        currentDayStreak: nil,
                        isPresentedModally: true
                    )
                } else {
                    // Resume from current page
                    StoryLabReadingView(config: config, isPresentedModally: true)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            Loc.StoryLab.History.emptyTitle,
            systemImage: "book.closed",
            description: Text(Loc.StoryLab.History.emptyDescription)
        )
        .frame(width: 400, height: 400)
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
        .frame(width: 500, height: 500)
    }
}


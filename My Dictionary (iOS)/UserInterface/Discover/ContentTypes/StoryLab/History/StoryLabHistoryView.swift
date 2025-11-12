//
//  StoryLabHistoryView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct StoryLabHistoryView: View {
    @StateObject private var viewModel = StoryLabHistoryViewModel()
    
    var body: some View {
        Group {
            if viewModel.sessions.isEmpty {
                emptyStateView
            } else {
                sessionsList
            }
        }
        .navigation(
            title: Loc.StoryLab.History.title,
            mode: .regular,
            showsBackButton: true
        )
        .task {
            viewModel.handleRefresh()
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
            ForEach(viewModel.sessions) { session in
                Button {
                    viewModel.navigate(to: session)
                } label: {
                    StoryLabSessionRow(session: session)
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                viewModel.deleteSessions(at: indexSet)
            }
        }
    }
}

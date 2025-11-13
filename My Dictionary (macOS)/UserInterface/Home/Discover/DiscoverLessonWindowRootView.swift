//
//  DiscoverLessonWindowRootView.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct DiscoverLessonWindowRootView: View {
    private let config: MusicPlayerConfig

    @StateObject private var playerViewModel: SongPlayerMacViewModel

    init(config: MusicPlayerConfig) {
        self.config = config
        _playerViewModel = StateObject(wrappedValue: .init(config: config))
    }

    var body: some View {
        NavigationSplitView {
            SongPlayerPane(viewModel: playerViewModel)
                .id(playerViewModel.song.id)
                .navigationSplitViewColumnWidth(min: 360, ideal: 380, max: 420)
        } detail: {
            lessonView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle(config.song.title)
    }

    @ViewBuilder
    private var lessonView: some View {
        switch playerViewModel.lessonState {
        case .loading:
            LessonLoadingView()
        case .ready(let lesson, let session):
            SongLessonPane(
                config: .init(
                    song: config.song,
                    lesson: lesson,
                    session: session
                )
            )
        case .failed(let message):
            LessonErrorView(
                message: message,
                onRetry: {
                    playerViewModel.handle(.generateLesson)
                }
            )
        }
    }
}

private struct LessonLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            AICircularProgressAnimation()
                .frame(maxWidth: 300)

            Text(Loc.MusicDiscovering.Player.Lesson.loading)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LessonErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.orange)

            Text(Loc.MusicDiscovering.Player.Lesson.failed)
                .font(.title2.weight(.semibold))

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            ActionButton(Loc.Actions.retry, style: .borderedProminent) {
                onRetry()
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

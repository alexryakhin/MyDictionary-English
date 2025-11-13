//
//  SongPlayerPane.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 11/12/25.
//

import SwiftUI

struct SongPlayerPane: View {
    @ObservedObject var viewModel: SongPlayerMacViewModel

    @Environment(\.openURL) private var openURL
    @State private var isTipsSheetPresented: Bool = false
    
    var body: some View {
        InteractiveLyricsView(viewModel: viewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .groupedBackground()
            .safeAreaBarIfAvailable {
                VStack(spacing: 8) {
                    playbackSection
                }
                .padding(16)
            }
            .onAppear {
                if !UDService.songPlayerTipsShown {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTipsSheetPresented = true
                    }
                }
            }
            .sheet(isPresented: $isTipsSheetPresented) {
                tipsSheetContent
            }
            .onChange(of: isTipsSheetPresented) { _, newValue in
                if newValue {
                    UDService.songPlayerTipsShown = true
                }
            }
            .onDisappear {
                if viewModel.isPlaying {
                    viewModel.handle(.playPause)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        isTipsSheetPresented = true
                    } label: {
                        Image(systemName: "info")
                    }
                }
            }
    }

    @ViewBuilder
    private var playbackSection: some View {
        switch viewModel.playbackState {
        case .loading, .active:
            playbackControls
        case .unavailable:
            youtubeFallbackView
        }
    }

    @ViewBuilder
    private var playbackControls: some View {
        VStack(spacing: 2) {
            SongProgressBar(
                isDragging: $viewModel.isSeeking,
                progress: $viewModel.currentTime,
                duration: viewModel.duration
            )

            HStack {
                Text(viewModel.formatTime(viewModel.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Spacer()

                Text(viewModel.formatTime(viewModel.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        ActionButton(
            viewModel.isPlaying ? Loc.Actions.pause : Loc.Actions.play,
            systemImage: viewModel.isPlaying ? "pause" : "play"
        ) {
            viewModel.handle(.playPause)
        }
        .disabled(!viewModel.sessionIsActive)
    }

    @ViewBuilder
    private var youtubeFallbackView: some View {
        VStack(spacing: 12) {
            Text(Loc.MusicDiscovering.Player.Playback.unavailableMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if let url = youtubeSearchURL {
                ActionButton(
                    Loc.MusicDiscovering.Player.Playback.openYoutube,
                    systemImage: "magnifyingglass"
                ) {
                    openURL(url)
                }
            }
        }
    }

    private var youtubeSearchURL: URL? {
        var components = URLComponents(string: "https://www.youtube.com/results")
        components?.queryItems = [
            URLQueryItem(
                name: "search_query",
                value: "\(viewModel.song.title) \(viewModel.song.artist)"
            )
        ]
        return components?.url
    }

    private var tipsSheetContent: some View {
        ScrollViewWithCustomNavBar {
            FormWithDivider(dividerLeadingPadding: .zero, dividerTrailingPadding: .zero) {
                tipRow(
                    icon: "list.bullet.rectangle",
                    title: Loc.MusicDiscovering.Player.Tips.exploreTitle,
                    message: Loc.MusicDiscovering.Player.Tips.exploreMessage
                )

                tipRow(
                    icon: "book.closed",
                    title: Loc.MusicDiscovering.Player.Tips.carryTitle,
                    message: Loc.MusicDiscovering.Player.Tips.carryMessage
                )

                tipRow(
                    icon: "sparkles",
                    title: Loc.MusicDiscovering.Player.Tips.pathTitle,
                    message: Loc.MusicDiscovering.Player.Tips.pathMessage
                )
            }
            .padding(vertical: 12, horizontal: 16)
        } navigationBar: {
            NavigationBarView(
                title: Loc.MusicDiscovering.Player.Tips.title,
                mode: .regular,
                showsDismissButton: false,
                trailingContent: {
                    HeaderButton(Loc.Actions.done) {
                        isTipsSheetPresented = false
                    }
                },
                bottomContent: {
                    Text(Loc.MusicDiscovering.Player.Tips.intro)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
        }
        .presentationDetents([.medium])
    }
    
    private func tipRow(icon: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.weight(.medium))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(.accent)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}

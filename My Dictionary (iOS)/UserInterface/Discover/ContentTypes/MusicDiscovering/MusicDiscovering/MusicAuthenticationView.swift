//
//  MusicAuthenticationView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct MusicAuthenticationView: View {
    @StateObject private var viewModel = MusicAuthenticationViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)

                Text(Loc.MusicDiscovering.Auth.Header.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Loc.MusicDiscovering.Auth.Header.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)

            // Service Options
            VStack(spacing: 16) {
                // Apple Music
                AuthenticationButton(
                    title: Loc.MusicDiscovering.Auth.Apple.connect,
                    icon: "apple.logo",
                    color: .red,
                    isLoading: viewModel.isAuthenticatingAppleMusic
                ) {
                    Task {
                        await viewModel.authenticateAppleMusic()
                    }
                }
            }
            .padding(.horizontal)

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Label(Loc.MusicDiscovering.Auth.Info.title, systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 4) {
                    InfoRow(Loc.MusicDiscovering.Auth.Info.recommendations)
                    InfoRow(Loc.MusicDiscovering.Auth.Info.library)
                    InfoRow(Loc.MusicDiscovering.Auth.Info.lyrics)
                    InfoRow(Loc.MusicDiscovering.Auth.Info.history)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            // Error Message
            if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)

                    if error == Loc.MusicDiscovering.Auth.Error.subscriptionRequired {
                        Button(Loc.MusicDiscovering.Auth.Actions.openMusicApp) {
                            if let url = URL(string: "music://") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding(vertical: 12, horizontal: 16)
    }
}

// MARK: - Authentication Button

private struct AuthenticationButton: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - View Model

@MainActor
final class MusicAuthenticationViewModel: ObservableObject {
    @Published var isAuthenticatingAppleMusic = false
    @Published var errorMessage: String?

    private let appleMusicService = AppleMusicService.shared
    
    func authenticateAppleMusic() async {
        isAuthenticatingAppleMusic = true
        errorMessage = nil
        
        do {
            try await appleMusicService.authenticate()
        } catch let error as MusicError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isAuthenticatingAppleMusic = false
    }
}


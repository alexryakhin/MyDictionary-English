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

                Text("Connect to Music Services")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Connect to Apple Music to discover personalized song recommendations for language learning.")
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
                    title: "Connect with Apple Music",
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
                Label("What you'll get:", systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 4) {
                    InfoRow("Personalized song recommendations")
                    InfoRow("Access to your music library")
                    InfoRow("Song lyrics and learning content")
                    InfoRow("Listening history tracking")
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

                    if error.contains("subscription") {
                        Button("Open Music App") {
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
            switch error {
            case .appleMusicSubscriptionRequired:
                errorMessage = "Apple Music subscription is required. You can subscribe in the Music app or Settings."
            case .appleMusicNotRegistered:
                errorMessage = "Apple Music is not available. This app needs to be registered for MusicKit."
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isAuthenticatingAppleMusic = false
    }
}


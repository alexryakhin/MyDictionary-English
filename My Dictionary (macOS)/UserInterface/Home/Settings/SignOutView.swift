//
//  SignOutView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SignOutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authenticationService = AuthenticationService.shared

    var body: some View {
        if authenticationService.showingSignOutView {
            ZStack {
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    // Icon and title
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 24))
                                .foregroundStyle(.accent)
                        }

                        Text("Sign Out")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    // Message
                    VStack(spacing: 8) {
                        Text("No worries! We won't remove your words.")
                            .font(.body)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)

                        Text("Your vocabulary will stay on this device. If you sign in with another account, your data will be combined.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        ActionButton("Sign Out", color: .red, style: .borderedProminent) {
                            authenticationService.signOut()
                        }

                        ActionButton("Cancel") {
                            authenticationService.toggleSignOutView()
                        }
                    }
                }
                .padding(24)
                .groupedBackground()
            }
        }
    }
}

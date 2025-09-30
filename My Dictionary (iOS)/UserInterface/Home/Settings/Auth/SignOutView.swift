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
                    .background(.thinMaterial)
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

                        Text(Loc.Auth.signOut)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    // Message
                    VStack(spacing: 8) {
                        Text(Loc.Auth.noWorriesWontRemoveWords)
                            .font(.body)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)

                        Text(Loc.Auth.vocabularyStayOnDevice)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Buttons
                    VStack(spacing: 12) {
                        ActionButton(Loc.Auth.signOut, color: .red, style: .borderedProminent) {
                            authenticationService.signOut()
                            dismiss()
                        }

                        ActionButton(Loc.Actions.cancel) {
                            authenticationService.toggleSignOutView()
                        }
                    }
                }
                .padding(24)
                .groupedBackground()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .label.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
            }
        }
    }
}

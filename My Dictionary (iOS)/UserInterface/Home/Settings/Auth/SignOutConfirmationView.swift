//
//  SignOutConfirmationView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SignOutConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: VoidHandler
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with icon
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accent.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 32))
                        .foregroundStyle(.accent)
                }

                Text(Loc.Auth.signOut)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // Main content
            VStack(spacing: 20) {
                // What stays
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                            .font(.title3)

                        Text(Loc.Auth.yourWordsAreSafe)
                            .font(.headline)
                            .fontWeight(.medium)
                    }

                    Text(Loc.Auth.allVocabularyRemainDevice)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)

                // What changes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.orange)
                            .font(.title3)

                        Text(Loc.Auth.cloudSyncDisabled)
                            .font(.headline)
                            .fontWeight(.medium)
                    }

                    Text(Loc.Auth.wordListsSharedDataCleared)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                ActionButton(
                    Loc.Actions.signOut,
                    systemImage: "rectangle.portrait.and.arrow.right",
                    color: .red,
                    style: .borderedProminent
                ) {
                    onConfirm()
                    dismiss()
                }

                ActionButton(Loc.Actions.cancel) {
                    dismiss()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
    }
}

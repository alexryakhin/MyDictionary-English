//
//  MigrationProgressView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import SwiftUI

struct MigrationProgressView: View {
    @StateObject private var migrationService = DataMigrationService.shared

    var body: some View {
        VStack(spacing: 24) {
            // App Icon or Logo
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text(Loc.Migration.updatingYourDictionary)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(Loc.Migration.enhancingVocabularyMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                // Progress Bar
                ProgressView(value: migrationService.progress.percentage)
                    .progressViewStyle(LinearProgressViewStyle())
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                // Phase Information
                VStack(spacing: 4) {
                    Text(migrationService.progress.phase.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if migrationService.progress.totalItems > 1 {
                        Text("\(migrationService.progress.currentItem)/\(migrationService.progress.totalItems)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !migrationService.progress.message.isEmpty {
                        Text(migrationService.progress.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Important Notice
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text(Loc.Migration.pleaseDontCloseApp)
                        .font(.footnote)
                        .fontWeight(.medium)
                }

                Text(Loc.Migration.dataSafeUpgradeMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.05))
        .onAppear {
            startMigrationIfNeeded()
        }
    }

    private func startMigrationIfNeeded() {
        guard migrationService.needsMigration else { return }

        Task { @MainActor in
            do {
                try await migrationService.performMigration()
            } catch {
                AlertCenter.shared.showAlert(
                    with: .init(
                        title: Loc.Migration.migrationError,
                        message: Loc.Migration.migrationFailedMessage(error.localizedDescription),
                        actionText: Loc.Actions.cancel,
                        additionalActionText: Loc.Actions.retry,
                        action: {},
                        additionalAction: {
                            retryMigration()
                        }
                    )
                )
                logError("Migration failed: \(error)")
            }
        }
    }

    private func retryMigration() {
        // Reset migration state and try again
        migrationService.resetMigrationState()

        // Small delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startMigrationIfNeeded()
        }
    }
}

#if DEBUG
struct MigrationProgressView_Previews: PreviewProvider {
    static var previews: some View {
        MigrationProgressView()
    }
}
#endif

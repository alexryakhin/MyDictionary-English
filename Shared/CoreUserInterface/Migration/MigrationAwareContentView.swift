//
//  MigrationAwareContentView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import SwiftUI

struct MigrationAwareContentView<Content: View>: View {
    @StateObject private var migrationService = DataMigrationService.shared
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Group {
            if migrationService.needsMigration || migrationService.isInProgress {
                MigrationProgressView()
            } else {
                content()
            }
        }
        .onAppear {
            // Check for migration on app launch
            if migrationService.needsMigration && !migrationService.isInProgress {
                Task {
                    do {
                        try await migrationService.performMigration()
                    } catch {
                        logError("Migration failed on app launch: \(error)")
                    }
                }
            }
        }
    }
}

// Extension to make it easier to use
extension View {
    func migrationAware() -> some View {
        MigrationAwareContentView {
            self
        }
    }
}

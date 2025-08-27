//
//  MigrationProgressView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/19/25.
//

import SwiftUI

struct MigrationProgressView: View {
    @StateObject private var migrationService = DataMigrationService.shared
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon or Logo
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Updating Your Dictionary")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We're enhancing your vocabulary with new features")
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
                    Text("Please don't close the app during this process")
                        .font(.footnote)
                        .fontWeight(.medium)
                }
                
                Text("Your data is being safely upgraded and will remain intact")
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
        .alert("Migration Error", isPresented: $showingError) {
            Button("Retry") {
                retryMigration()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let error = migrationService.error {
                Text("Migration failed: \(error.localizedDescription)\n\nWould you like to retry?")
            }
        }
    }
    
    private func startMigrationIfNeeded() {
        guard migrationService.needsMigration else { return }
        
        Task {
            do {
                try await migrationService.performMigration()
            } catch {
                logError("Migration failed: \(error)")
                // Error handling is done through the @Published error property
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

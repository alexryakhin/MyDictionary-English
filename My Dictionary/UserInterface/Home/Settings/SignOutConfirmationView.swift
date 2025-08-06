//
//  SignOutConfirmationView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SignOutConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.crop.circle.badge.minus")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Sign Out")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                // Main content
                VStack(spacing: 20) {
                    // What stays
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            
                            Text("Your words are safe")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Text("All your vocabulary words, definitions, and progress will remain on this device. You can continue using the app offline.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                    
                    // What changes
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.orange)
                                .font(.title3)
                            
                            Text("Cloud sync will be disabled")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        
                        Text("Word lists and shared data will be cleared. If you sign in with another account, your local words will be combined with the new account's data.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

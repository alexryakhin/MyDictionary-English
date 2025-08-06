//
//  SignOutAlertView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct SignOutAlertView: View {
    @Environment(\.dismiss) private var dismiss
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon and title
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
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
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Buttons
            VStack(spacing: 8) {
                Button {
                    #if os(iOS)
                    HapticManager.shared.triggerNotification(type: .success)
                    #endif
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button {
                    #if os(iOS)
                    HapticManager.shared.triggerSelection()
                    #endif
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 40)
    }
}

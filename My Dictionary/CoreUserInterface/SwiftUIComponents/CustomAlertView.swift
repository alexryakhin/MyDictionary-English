//
//  CustomAlertView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/8/25.
//

import SwiftUI

struct CustomAlertView: View {
    let alertModel: AlertModel
    let isPresented: Binding<Bool>
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with icon
            HStack(spacing: 12) {
                Image(systemName: alertModel.icon)
                    .foregroundColor(alertModel.iconColor)
                    .font(.title2)
                
                Text(alertModel.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Message
            if let message = alertModel.message {
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Cancel/Info button
                if let actionText = alertModel.actionText {
                    Button(actionText) {
                        alertModel.action?()
                        isPresented.wrappedValue = false
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                
                // Destructive button
                if let destructiveText = alertModel.destructiveActionText {
                    Button(destructiveText) {
                        alertModel.destructiveAction?()
                        isPresented.wrappedValue = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(alertModel.alertType == .error ? .red : .blue)
                    .frame(maxWidth: .infinity)
                }
                
                // Additional button
                if let additionalText = alertModel.additionalActionText {
                    Button(additionalText) {
                        alertModel.additionalAction?()
                        isPresented.wrappedValue = false
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(alertModel.backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }
}

struct CustomAlertModifier: ViewModifier {
    let alertModel: AlertModel
    let isPresented: Binding<Bool>
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented.wrappedValue {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isPresented.wrappedValue = false
                            }
                        
                        CustomAlertView(alertModel: alertModel, isPresented: isPresented)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
            )
    }
}

extension View {
    func customAlert(_ alertModel: AlertModel, isPresented: Binding<Bool>) -> some View {
        modifier(CustomAlertModifier(alertModel: alertModel, isPresented: isPresented))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Alert Examples")
            .font(.title)
        
        Button("Show Info Alert") {
            // Example usage
        }
        .buttonStyle(.borderedProminent)
        
        Button("Show Warning Alert") {
            // Example usage
        }
        .buttonStyle(.borderedProminent)
        
        Button("Show Error Alert") {
            // Example usage
        }
        .buttonStyle(.borderedProminent)
        
        Button("Show Confirmation Alert") {
            // Example usage
        }
        .buttonStyle(.borderedProminent)
        
        Button("Show Choice Alert") {
            // Example usage
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
} 
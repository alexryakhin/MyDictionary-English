//
//  CoffeeBanner.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/10/25.
//

import SwiftUI

struct CoffeeBanner: View {
    let onBuyCoffee: VoidHandler
    let onDismiss: VoidHandler
    
    @State private var animate = false
    @State private var showPulse = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with coffee icon and message
            VStack(spacing: 12) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .scaleEffect(showPulse ? 1.1 : 1.0)
                        
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(Color.orange)
                            .scaleEffect(animate ? 1.0 : 0.8)
                            .rotationEffect(.degrees(animate ? 0 : -10))
                    }
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showPulse)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animate)
                    
                    Spacer()
                    
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Enjoying the app?")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("If My Dictionary has been helpful in your learning journey, consider buying me a coffee! ☕️")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                ActionButton("Buy Me a Coffee", systemImage: "cup.and.saucer.fill", color: .orange, style: .borderedProminent) {
                    onBuyCoffee()
                }
                ActionButton("Maybe Later") {
                    onDismiss()
                }
            }
        }
        .padding(20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animate = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    showPulse = true
                }
            }
        }
    }
}

#Preview {
    CoffeeBanner(
        onBuyCoffee: {},
        onDismiss: {}
    )
    .padding()
}

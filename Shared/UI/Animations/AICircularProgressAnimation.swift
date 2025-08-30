//
//  AICircularProgressAnimation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AICircularProgressAnimation: View {
    @State private var progress: CGFloat = 0.0
    @State private var brainScale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Circular progress
                Circle()
                    .stroke(.accent.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: progress
                    )
                
                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .scaleEffect(brainScale)
                    .rotationEffect(.degrees(rotation))
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: brainScale
                    )
            }
            
            VStack(spacing: 8) {
                Text("AI is computing...")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Running advanced algorithms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.accent.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.accent.opacity(0.2), lineWidth: 1)
                }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        progress = 1.0
        brainScale = 1.2
        rotation = 360
    }
}

#Preview {
    VStack(spacing: 20) {
        AICircularProgressAnimation()
            .frame(maxWidth: 300)
        
        Text("Circular Progress Animation")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.systemGroupedBackground)
}

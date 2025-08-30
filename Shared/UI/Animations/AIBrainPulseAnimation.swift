//
//  AIBrainPulseAnimation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AIBrainPulseAnimation: View {
    @State private var brainScale: CGFloat = 1.0
    @State private var brainOpacity: Double = 1.0
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]
    
    var body: some View {
        HStack(spacing: 12) {
            // Pulsing brain icon
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.accent)
                .scaleEffect(brainScale)
                .opacity(brainOpacity)
                .animation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                    value: brainScale
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(Loc.Ai.AiAnimation.thinking)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(Loc.Ai.AiAnimation.analyzingWord)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            
            // Rotating dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.accent)
                        .frame(width: 6, height: 6)
                        .scaleEffect(dotScales[index])
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: dotScales[index]
                        )
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.accent.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.accent.opacity(0.3), lineWidth: 1)
                }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        brainScale = 1.2
        brainOpacity = 0.6
        dotScales = [1.5, 1.5, 1.5]
    }
}

#Preview {
    VStack(spacing: 20) {
        AIBrainPulseAnimation()
            .frame(maxWidth: 350)
        
        Text("Brain Pulse Animation")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.systemGroupedBackground)
}

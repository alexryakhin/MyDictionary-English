//
//  AISparklesAnimation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AISparklesAnimation: View {
    @State private var sparkleOffsets: [CGSize] = Array(repeating: .zero, count: 8)
    @State private var sparkleOpacities: [Double] = Array(repeating: 0.0, count: 8)
    @State private var brainScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background sparkles
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(.accent)
                        .offset(sparkleOffsets[index])
                        .opacity(sparkleOpacities[index])
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.25),
                            value: sparkleOpacities[index]
                        )
                }
                
                // Central brain icon
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundStyle(.accent)
                    .scaleEffect(brainScale)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: brainScale
                    )
            }
            
            VStack(spacing: 8) {
                Text("AI is analyzing...")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Finding the perfect definitions for you")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.accent.opacity(0.08))
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
        sparkleOffsets = (0..<8).map { index in
            let angle = Double(index) * .pi * 2 / 8
            let radius: CGFloat = 40
            return CGSize(
                width: cos(angle) * radius,
                height: sin(angle) * radius
            )
        }
        sparkleOpacities = Array(repeating: 1.0, count: 8)
        brainScale = 1.3
    }
}

#Preview {
    VStack(spacing: 20) {
        AISparklesAnimation()
            .frame(maxWidth: 300)
        
        Text("Sparkles Animation")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.systemGroupedBackground)
}

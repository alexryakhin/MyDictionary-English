//
//  AIHueRotationAnimation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AIHueRotationAnimation: View {
    @State private var hueRotation: Double = 0.0
    @State private var brainScale: CGFloat = 1.0
    @State private var dotScales: [CGFloat] = [1.0, 1.0, 1.0]
    
    var body: some View {
        HStack(spacing: 16) {
            // Hue rotating brain icon
            Image(systemName: "brain.head.profile")
                .font(.title)
                .foregroundStyle(.accent)
                .hueRotation(.degrees(hueRotation))
                .scaleEffect(brainScale)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: brainScale
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(Loc.Ai.AiAnimation.processing)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Animated progress dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.accent)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotScales[index])
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                                value: dotScales[index]
                            )
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.accent.opacity(0.1))
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        hueRotation = 360
        brainScale = 1.2
        dotScales = [1.8, 1.8, 1.8]
    }
}

#Preview {
    VStack(spacing: 20) {
        AIHueRotationAnimation()
            .frame(maxWidth: 350)
        
        Text("Hue Rotation Animation")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.systemGroupedBackground)
}

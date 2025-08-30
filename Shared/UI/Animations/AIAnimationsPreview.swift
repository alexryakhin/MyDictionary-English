//
//  AIAnimationsPreview.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AIAnimationsPreview: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                Text("AI Loading Animations")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Choose the perfect animation for your AI-powered definition loading")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Group {
                    animationSection(
                        title: "Brain Pulse Animation",
                        description: "Elegant pulsing brain with animated dots",
                        animation: AIBrainPulseAnimation()
                    )
                    
                    animationSection(
                        title: "Sparkles Animation",
                        description: "Premium feel with rotating sparkles",
                        animation: AISparklesAnimation()
                    )
                    
                    animationSection(
                        title: "Hue Rotation Animation",
                        description: "Modern color-shifting effect",
                        animation: AIHueRotationAnimation()
                    )
                    
                    animationSection(
                        title: "Wave Animation",
                        description: "Smooth wave background effect",
                        animation: AIWaveAnimation()
                    )
                    
                    animationSection(
                        title: "Circular Progress Animation",
                        description: "Classic progress ring with rotation",
                        animation: AICircularProgressAnimation()
                    )
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .background(Color.systemGroupedBackground)
    }
    
    @ViewBuilder
    private func animationSection(
        title: String,
        description: String,
        animation: some View
    ) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            animation
                .frame(maxWidth: 350)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

#Preview {
    AIAnimationsPreview()
}

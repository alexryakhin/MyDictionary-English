//
//  AIWaveAnimation.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 3/9/25.
//

import SwiftUI

struct AIWaveAnimation: View {
    @State private var waveOffset: CGFloat = 0.0
    @State private var brainScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Wave background
                WaveShape(offset: waveOffset)
                    .fill(.accent.opacity(0.2))
                    .frame(height: 60)
                    .animation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                        value: waveOffset
                    )
                
                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundStyle(.accent)
                    .scaleEffect(brainScale)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: brainScale
                    )
            }
            
            VStack(spacing: 8) {
                Text(Loc.Ai.AiAnimation.learning)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(Loc.Ai.AiAnimation.processingNeural)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
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
        waveOffset = 1.0
        brainScale = 1.3
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * 2 * .pi + offset * 2 * .pi)
            let y = midHeight + sine * 20
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        AIWaveAnimation()
            .frame(maxWidth: 300)
        
        Text("Wave Animation")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.systemGroupedBackground)
}

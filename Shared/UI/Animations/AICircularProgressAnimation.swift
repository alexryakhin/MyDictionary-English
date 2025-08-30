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
    @State private var currentPhraseIndex: Int = 0
    @State private var phraseOpacity: Double = 1.0
    
    private let phrases = [
        Loc.Ai.AiLoading.computing,
        Loc.Ai.AiLoading.analyzingContext,
        Loc.Ai.AiLoading.findingDefinitions,
        Loc.Ai.AiLoading.processingLanguage,
        Loc.Ai.AiLoading.runningAlgorithms,
        Loc.Ai.AiLoading.understandingMeaning,
        Loc.Ai.AiLoading.generatingInsights,
        Loc.Ai.AiLoading.learningPatterns
    ]
    
    private let descriptions = [
        Loc.Ai.AiLoadingDesc.runningAlgorithms,
        Loc.Ai.AiLoadingDesc.examiningRelationships,
        Loc.Ai.AiLoadingDesc.searchingKnowledge,
        Loc.Ai.AiLoadingDesc.understandingNuances,
        Loc.Ai.AiLoadingDesc.applyingMachineLearning,
        Loc.Ai.AiLoadingDesc.extractingSemantic,
        Loc.Ai.AiLoadingDesc.creatingDefinitions,
        Loc.Ai.AiLoadingDesc.identifyingPatterns
    ]
    
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
                Text(phrases[currentPhraseIndex])
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .opacity(phraseOpacity)
                    .animation(.easeInOut(duration: 0.5), value: phraseOpacity)
                
                Text(descriptions[currentPhraseIndex])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(phraseOpacity)
                    .animation(.easeInOut(duration: 0.5), value: phraseOpacity)
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
        progress = 1.0
        brainScale = 1.2
        rotation = 360
        startPhraseAnimation()
    }
    
    private func startPhraseAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                phraseOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentPhraseIndex = (currentPhraseIndex + 1) % phrases.count
                withAnimation(.easeInOut(duration: 0.5)) {
                    phraseOpacity = 1.0
                }
            }
        }
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

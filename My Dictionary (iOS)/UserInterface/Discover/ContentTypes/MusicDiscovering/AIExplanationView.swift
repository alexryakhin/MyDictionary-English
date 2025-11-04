//
//  AIExplanationView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin
//

import SwiftUI

struct AIExplanationView: View {
    let explanations: [LyricExplanation]
    let culturalContext: String?
    @Environment(\.dismiss) private var dismiss
    
    @State private var expandedIndices: Set<Int> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Cultural Context
                    if let culturalContext = culturalContext {
                        culturalContextSection(context: culturalContext)
                    }
                    
                    // Lyric Explanations
                    explanationsSection
                }
                .padding()
            }
            .groupedBackground()
            .navigation(title: "Song Explanation", mode: .inline, trailingContent: {
                HeaderButton(Loc.Actions.done) {
                    dismiss()
                }
            })
        }
    }
    
    // MARK: - Cultural Context Section
    
    private func culturalContextSection(context: String) -> some View {
        CustomSectionView(header: "Cultural Context") {
            Text(context)
                .font(.body)
                .textSelection(.enabled)
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Explanations Section
    
    private var explanationsSection: some View {
        CustomSectionView(header: "Lyric Explanations") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(explanations.enumerated()), id: \.offset) { index, explanation in
                    explanationCard(explanation: explanation, index: index)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func explanationCard(explanation: LyricExplanation, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                if expandedIndices.contains(index) {
                    expandedIndices.remove(index)
                } else {
                    expandedIndices.insert(index)
                }
            }) {
                HStack {
                    Text(explanation.lyricLine)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: expandedIndices.contains(index) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if expandedIndices.contains(index) {
                Text(explanation.explanation)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(Color.secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

#Preview {
    AIExplanationView(
        explanations: [
            LyricExplanation(
                lyricLine: "La vida es un carnaval",
                explanation: "Life is a carnival - This phrase suggests that life should be celebrated like a carnival, with joy and festivity despite hardships.",
                lineNumber: 1
            )
        ],
        culturalContext: "This song explores themes of celebration and joy in the face of adversity."
    )
}


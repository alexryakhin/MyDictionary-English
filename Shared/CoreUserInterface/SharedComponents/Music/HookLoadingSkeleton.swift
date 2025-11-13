//
//  HookLoadingSkeleton.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/13/25.
//

import SwiftUI

struct HookLoadingSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Main Hook Text Shimmer (multiline)
            VStack(alignment: .leading, spacing: 8) {
                ShimmerView(height: 16)
                ShimmerView(height: 16)
                ShimmerView(width: 250, height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Key Phrases Section
            VStack(alignment: .leading, spacing: 12) {
                ShimmerView(width: 100, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Phrase 1
                HStack(alignment: .top, spacing: 8) {
                    ShimmerView(width: 40, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView(width: 200, height: 14)
                        ShimmerView(width: 150, height: 12)
                        ShimmerView(width: 180, height: 10)
                    }
                }
                
                // Phrase 2
                HStack(alignment: .top, spacing: 8) {
                    ShimmerView(width: 40, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView(width: 180, height: 14)
                        ShimmerView(width: 160, height: 12)
                        ShimmerView(width: 190, height: 10)
                    }
                }
                
                // Phrase 3
                HStack(alignment: .top, spacing: 8) {
                    ShimmerView(width: 40, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 4) {
                        ShimmerView(width: 190, height: 14)
                        ShimmerView(width: 140, height: 12)
                        ShimmerView(width: 170, height: 10)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Grammar Highlight Shimmer
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ShimmerView(width: 16, height: 16)
                    ShimmerView(width: 80, height: 14)
                }
                ShimmerView(height: 12)
                ShimmerView(width: 220, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))

            // Cultural Note Shimmer
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ShimmerView(width: 16, height: 16)
                    ShimmerView(width: 100, height: 14)
                }
                ShimmerView(height: 12)
                ShimmerView(width: 240, height: 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clippedWithPaddingAndBackground(Color.accent.opacity(0.1))
        }
    }
}

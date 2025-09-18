//
//  QuizCardView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct QuizCardView: View {
    let quiz: Quiz
    
    var body: some View {
        HStack(spacing: 8) {
            // Quiz Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(quiz.color.gradient)
                    .frame(width: 50, height: 50)
                    .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 12))

                Image(systemName: quiz.iconName)
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(quiz.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .multilineTextAlignment(.leading)
        .contentShape(.rect)
    }
}

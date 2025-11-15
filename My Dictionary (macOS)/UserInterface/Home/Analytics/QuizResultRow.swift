//
//  QuizResultRow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct QuizResultRow: View {
    let session: CDQuizSession

    var body: some View {
        HStack(spacing: 12) {
            // Quiz Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(session.quizColor.gradient)
                    .frame(width: 36, height: 36)

                Image(systemName: session.quizIconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.quiz?.title ?? session.quizTitleFromType)
                    .font(.body)
                    .fontWeight(.medium)

                Text(session.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Loc.Plurals.Analytics.pointsCount(Int(session.score)))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.accent)

                Text("\(Int(session.accuracy * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .clippedWithBackground(Color.tertiarySystemGroupedBackground, in: .rect(cornerRadius: 12))
    }
}

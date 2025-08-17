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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text((session.quiz?.title ?? ""))
                    .font(.body)
                    .fontWeight(.medium)

                Text(session.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Loc.Analytics.pointsCount.localized(Int(session.score)))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.accent)

                Text("\(Int(session.accuracy * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .clippedWithBackground(Color.tertiarySystemGroupedBackground, cornerRadius: 12)
    }
}

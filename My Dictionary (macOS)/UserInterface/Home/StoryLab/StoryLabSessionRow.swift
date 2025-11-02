//
//  StoryLabSessionRow.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 11/2/25.
//

import SwiftUI

struct StoryLabSessionRow: View {
    @StateObject var session: CDStoryLabSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(session.title ?? Loc.StoryLab.Session.defaultTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let date = session.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                TagView(
                    text: "\(session.score)%",
                    systemImage: "star.fill",
                    color: .yellow,
                    size: .small,
                    style: session.isComplete ? .selected : .regular
                )

                TagView(
                    text: "\(session.correctAnswers)/\(session.totalQuestions)",
                    systemImage: "checkmark.circle.fill",
                    color: .green,
                    size: .small,
                    style: session.isComplete ? .selected : .regular
                )

                if let language = session.targetLanguage {
                    TagView(
                        text: language.uppercased(),
                        systemImage: "globe",
                        color: .blue,
                        size: .small,
                        style: session.isComplete ? .selected : .regular
                    )
                }
            }
            
            if !session.discoveredWords.isEmpty {
                Text("\(session.discoveredWords.count) \(Loc.StoryLab.Session.wordsDiscovered)")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}


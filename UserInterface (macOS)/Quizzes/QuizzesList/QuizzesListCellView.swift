//
//  QuizzesListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI

struct QuizzesListCellView: View {
    var quiz: Quiz

    var body: some View {
        HStack(spacing: 8) {
            Text(quiz.title)
                .bold()
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(vertical: 12, horizontal: 16)
    }
}

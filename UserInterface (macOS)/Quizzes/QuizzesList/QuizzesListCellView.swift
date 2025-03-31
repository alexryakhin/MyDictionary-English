//
//  QuizzesListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI
import Core
import CoreUserInterface__macOS_

struct QuizzesListCellView: View {
    var quiz: Quiz

    var body: some View {
        HStack(spacing: 8) {
            Text(quiz.title)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(vertical: 12, horizontal: 16)
    }
}

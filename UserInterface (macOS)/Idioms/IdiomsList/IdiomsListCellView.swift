//
//  IdiomsListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI
import Core

struct IdiomsListCellView: View {
    var idiom: Idiom

    var body: some View {
        HStack(spacing: 8) {
            Text(idiom.idiom)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if idiom.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

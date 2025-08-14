//
//  IdiomListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI

struct IdiomListCellView: View {
    @StateObject private var idiom: CDIdiom

    init(idiom: CDIdiom) {
        self._idiom = StateObject(wrappedValue: idiom)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(idiom.idiomItself ?? "")
                .bold()
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if idiom.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.accent)
            }

            Image(systemName: "chevron.right")
                .frame(sideLength: 12)
                .foregroundStyle(.secondary)
        }
        .padding(vertical: 12, horizontal: 16)
        .background(Color.secondarySystemGroupedBackground)
    }

    struct Model {
        var idiom: String
        var isFavorite: Bool
    }
}

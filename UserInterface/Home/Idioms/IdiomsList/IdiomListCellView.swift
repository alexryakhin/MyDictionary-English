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
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if idiom.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }

            Image(systemName: "chevron.right")
                .frame(sideLength: 12)
                .foregroundColor(.secondary)
        }
    }

    struct Model {
        var idiom: String
        var isFavorite: Bool
    }
}

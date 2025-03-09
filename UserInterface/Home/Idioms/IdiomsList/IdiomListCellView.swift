//
//  IdiomListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI
import CoreUserInterface

struct IdiomListCellView: ConfigurableView {
    var model: Model

    var body: some View {
        HStack(spacing: 8) {
            Text(model.idiom)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if model.isFavorite {
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

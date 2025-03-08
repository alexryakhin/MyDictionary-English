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
        HStack {
            Text(model.idiom)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            if model.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
    }

    struct Model {
        var idiom: String
        var isFavorite: Bool
    }
}

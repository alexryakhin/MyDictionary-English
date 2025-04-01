//
//  IdiomsListCellView.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 2/22/25.
//

import SwiftUI
import Core
import CoreUserInterface__macOS_

struct IdiomsListCellView: View {
    var idiom: Idiom
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(idiom.idiom)
                .bold()
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if idiom.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .accentColor)
            }
        }
        .padding(vertical: 4, horizontal: 8)
    }
}

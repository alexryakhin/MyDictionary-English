//
//  SharedDictionariesListCellView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/12/25.
//

import SwiftUI

struct SharedDictionariesListCellView: View {

    let dictionary: SharedDictionary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dictionary.name)
                    .font(.headline)

                HStack {
                    if dictionary.isOwner {
                        Text(Loc.SharedDictionaries.collaborators.localized(dictionary.collaborators.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TagView(text: Loc.SharedDictionaries.owner.localized, color: .accent, size: .mini)
                    } else if let owner = dictionary.collaborators.first(where: { $0.role == .owner }) {
                        Text(Loc.SharedDictionaries.createdBy.localized(owner.displayNameOrEmail))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .frame(sideLength: 12)
                .foregroundStyle(.secondary)
        }
        .padding(vertical: 12, horizontal: 16)
        .background(Color.secondarySystemGroupedBackground)
    }
}

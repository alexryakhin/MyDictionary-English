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
            Image(systemName: "person.2")
                .foregroundStyle(.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(dictionary.name)
                    .font(.headline)

                HStack {
                    if dictionary.isOwner {
                        Text("\(dictionary.collaborators.count) collaborators")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Owner")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                    } else if let owner = dictionary.collaborators.first(where: { $0.role == .owner }) {
                        Text("Created by \(owner.displayNameOrEmail)")
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
        .background(Color(.secondarySystemGroupedBackground))
    }
}

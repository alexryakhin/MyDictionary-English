//
//  TagRowView.swift
//  My Dictionary
//
//  Created by Alexander Riakhin on 8/15/25.
//

import SwiftUI

struct TagRowView: View {
    let tag: CDTag
    let onEdit: VoidHandler
    let onDelete: VoidHandler

    var body: some View {
        HStack {
            // Tag Color Indicator
            Circle()
                .fill(tag.colorValue.color)
                .frame(width: 12, height: 12)

            // Tag Name
            VStack(alignment: .leading, spacing: 2) {
                Text(tag.name ?? "")
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(tag.wordsArray.count) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .padding(4)
                    .background(Color.gray.opacity(0.01))
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
    }
}

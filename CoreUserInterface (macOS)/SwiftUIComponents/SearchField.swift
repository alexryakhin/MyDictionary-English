//
//  SearchField.swift
//  My Dictionary (macOS)
//
//  Created by Aleksandr Riakhin on 3/31/25.
//

import SwiftUI

public struct SearchField: View {

    private var text: Binding<String>

    public init(text: Binding<String>) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: text)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.textFieldColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background {
            RoundedRectangle(cornerRadius: 4)
                .stroke(lineWidth: 2)
                .foregroundStyle(Color.separatorColor)
        }
    }
}

//
//  CustomSectionHeader.swift
//  RepsCount
//
//  Created by Aleksandr Riakhin on 3/19/25.
//

import SwiftUI

public struct CustomSectionHeader: View {

    private let text: LocalizedStringKey

    public init(text: LocalizedStringKey) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//
//  ListButton.swift
//  My Dictionary
//
//  Created by Aleksandr Riakhin on 4/2/25.
//

import SwiftUI
import Shared

public struct ListButton: View {
    private let titleKey: LocalizedStringKey
    private let systemImageName: String
    private let foregroundColor: Color
    private let action: VoidHandler

    public init(
        _ titleKey: LocalizedStringKey,
        systemImage name: String,
        foregroundColor: Color = .accentColor,
        action: @escaping VoidHandler
    ) {
        self.titleKey = titleKey
        self.systemImageName = name
        self.foregroundColor = foregroundColor
        self.action = action
    }

    public var body: some View {
        CellWrapper {
            Button(action: action) {
                Label(titleKey, systemImage: systemImageName)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
        }
        .foregroundColor(foregroundColor)
    }
}
